# WordPress con balanceador de carga en AWS 🌐⚖️💻

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/9/93/Wordpress_Blue_logo.png" width="15%" height=15%"/>
  <img src="https://logos-world.net/wp-content/uploads/2021/08/Amazon-Web-Services-AWS-Logo.png" width="25%" height=25%"/>
</p>

## 🚩 Introducción

En esta memoria se va a detallar paso a paso el proceso seguido para crear un entorno de producción WordPress en Amazon Web Services.

Se busca desarrollar una infraestructura con la siguiente arquitectura:

<p align="center">
  <img src="https://hurricane-bus-a8e.notion.site/image/https%3A%2F%2Fs3-us-west-2.amazonaws.com%2Fsecure.notion-static.com%2F16b554e0-3bd0-49db-8ab4-3fc8bd509c83%2FUntitled_Diagram.drawio_(2).png?table=block&id=99d68263-3789-4f23-8249-ba6665c0f091&spaceId=6b9bdb2f-3da3-4962-8ae0-e1a15722e216&width=2000&userId=&cache=v2" width="30%" height="30%"/>
</p>

La solución se compone de una instancia de tipo balanceador que se comunicará con una instancia que actuará como aplicación WordPress.

Los usuarios de esta arquitectura se comunicarán exclusivamente con el balanceador de carga por medio del puerto 80 o 443 (HTTP y HTTPS) y este enrutará el tráfico hacia la instancia de aplicación.

La arquitectura cuenta con una serie de requisitos técnicos que se deben cumplir:

1. La instancia de aplicación solo tiene que aceptar tráfico del balanceador
2. El acceso SSH a las instancias tiene que estar securizado
3. Es recomendable usar un servicio de cloud público (AWS o GCP)

## 🛠️ Desarrollo y Configuración

Para el desarrollo de esta infraestructura he elegido AWS por el amplio catálogo de servicios que ofrece. Además, al ser una de las nubes más utilizadas existe una amplia documentación, así como una comunidad en constante crecimiento que proporciona guías y soporte a través de foros.

Vamos a ver una vista más detallada de la infraestructura que se busca desarrollar en AWS:

![2-solucion](https://user-images.githubusercontent.com/100093310/195448431-8598a54f-4c13-48d0-b16c-64417ad1c155.png)

Los clientes se conectan al **balanceador (LB)** a través de HTTP o HTTPS. Este balanceador de carga tiene asociado un **grupo de destino (LB-gd)** que se encarga de enviar el tráfico a la **instancia WordPress (WP)**.

Además, LB y WP tienen diferentes grupos de seguridad que filtran el tráfico que reciben. LB permite el tráfico HTTP y HTTPS del exterior y WP permite HTTP (y HTTPS) sólo si proviene del balanceador LB.

La configuración de los componentes de la infraestructura se detalla a continuación.

## 🔷 Instancias
### **[wp] Instancia de aplicación WordPress** 

| Parámetros | Valor |
| ------ | ------ |
| Nombre | wp |
| ID Instancia | i-08d42effe0f34b884 |
| Tipo de instancia | t2.micro |
| Zona de disponibilidad | us-east-1a |
| AMI ID | ami-04430ccc36585eb1d |
| Plataforma | Debian 11 |
| Grupo de seguridad | WP-sg |

Para facilitar el despliegue, en esta instancia he usado una AMI del AWS Marketplace. En concreto la imagen es "WordPress Certified by Bitnami and Automattic", es una imagen con base Debian con un WordPress ya configurado y actualizado a su ultima versión. Está respaldada por Bitnami, una empresa de VMware.

> El usuario y contraseña para WordPress se encuentran en el *log* de la instancia. La información del usuario Linux está publicada en un [README](https://bitnami.com/stack/wordpress/README.txt) por Bitnami.

Como alternativa se podría usar una imagen con base Linux e instalar WordPress manualmente por medio de SSH o automatizado por medio de comandos en el despliegue, esta alternativa permite una mayor personalización de la instacia base así como de los servicios utilizados. En esta ocasión, para facilitar el despliegue y el desarrollo de la insfraestructura, me decantaré por la primera opción. Una vez creada la infraestructura se podría pasar al desarrollo de la instancia personalizada fácilmente cambiando la imagen de la instancia.

## ⚖️ Equilibrio de carga
Los balanceadores de carga de encargan de distribuir el tráfico de forma equilibrada entre un grupo de instancias asociadas mediante un grupo de destino. En esta ocación solo tenemos una instancia, pero en caso de tener varias se distribuiría el tráfico de forma equilibrada entre ellas.
### **[LB] Balanceador de carga**

| Parámetros | Valor |
| ------ | ------ |
| Nombre | balanceador-de-carga |
| Tipo | application |
| Esquema | internet-facing |
| Zonas de disponibilidad | us-east-1a, us-east-1b  |
| Tipo de dirección IP | IPv4  |
| Grupo de seguridad | LB-sg |

Los **agentes de escucha** asociados a este balanceador son los siguientes:

### **Agentes de escucha**

| Nombre | Política de seguridad | SSL | Regla
| ------ | ------ | ------ | ------ |
| HTTP : 80 | n/a | n/a | reenviando a **LB-gp**
| HTTPS : 443 | ELBSecurityPolicy-2016-08 | Sí | reenviando a **LB-gp**

> Para que el balanceador reciba tráfico HTTPS hay que configurar un certificado SSL con el servicio AWS Certificate Manager.

Como se puede observar, estos **agentes de escucha** capturan el tráfico HTTP y HTTPS y lo reenvían al **grupo de destino LB-gp** que se detalla a continuación:

### **[LB-gp] Grupo de destino**

| [Entrada] | Nombre | Puerto | Protocolo | Versión protocolo | Tipo destino | Balanceador de carga |
| ------ | ------ | ------ | ------ |  ------ |  ------ |  ------ |
|| LB-gp | 80 | HTTP | HTTP1 | instance | balanceador-de-carga |
| **[Destinos]** | **ID de instancia** | **Puerto**  | **Zona de disponibilidad** | **Estado** |  |  |
|| i-08d42effe0f34b884 | 80 | us-east-1a | healthy | | |

Este grupo de destino pasa el tráfico a la instancia WordPress.

## 🛡️ Grupos de seguridad
En este apartado se definen las reglas de tráfico tanto para el balanceador de carga como para la instacia WordPress.
### **[LB-sg] (sg-04768547f40b5c8dc)**

| Entrada | ID regla | Versión IP | Tipo | Protocolo | Puertos | Origen |
| ------ | ------ | ------ | ------ |  ------ |  ------ |  ------ |
|| sgr-014565a3637f4fe8d | IPv4 | HTTP | TCP | 80 | 0.0.0.0/0 |
|| sgr-0fd17cbdb87d2b9bb | IPv4 | HTTPS | TCP | 443 | 0.0.0.0/0 | 
|| sgr-0dc8bb23177eac788 | IPv4 | SSH | TCP | 22 | 0.0.0.0/0 | 
| **Salida** |  |  |  |  |  |  |
|  | sgr-06496b4ea15dce0ff | IPv4 | Todo el tráfico | Todo | Todo | 0.0.0.0/0 |

> Para este grupo de seguridad no es necesario habilitar el protocolo SSH, ya que en AWS los balanceadores de carga de aplicación no son accesibles mediante este protocolo.

### **[WP-sg] (sg-06c861be8eb7f6425)**

| Entrada | ID regla | Versión IP | Tipo | Protocolo | Puertos | Origen |
| ------ | ------ | ------ | ------ |  ------ |  ------ |  ------ |
|  | sgr-0c642ac89ae4e7a86 | - | HTTP | TCP | 80 | sg-04768547f40b5c8dc / LB-sg |
|  | sgr-0d1c5f7dfeca2b856 | - | HTTPS | TCP | 443 | sg-04768547f40b5c8dc / LB-sg | 
|  | sgr-0f2933522930687de | IPv4 | SSH | TCP | 22 | 0.0.0.0/0 |
| **Salida** |  |  |  |  |  |  |
|  | sgr-033c518f62a9d1518 | IPv4 | Todo el tráfico | Todo | Todo | 0.0.0.0/0 |

> Destacar aquí el origen del tráfico HTTP y HTTPS, como se puede observar únicamente se permite el proveniente del balanceador de carga. Esto se define estableciendo como origen el grupo de seguridad del balanceador.

## 👨‍💻 Bonus - Infraestructura como código

<p align="center">
 <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Terraform_Logo.svg/1280px-Terraform_Logo.svg.png" width="60%" height="60%">
</p>

Para finalizar, en este repositorio se puede encontrar toda esta infraestructura automatizada para que se pueda crear y destruir desde un solo comando.

Para esto he utilizado Terraform, un software de infraestructura que permite la creación de esta en los principales servicios de *cloud*.

Después de documentarme sobre los fundamentos de Terraform, he ido consultado su [documentación para AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) y pasando cada componente de la infraestructura con su configuración correspondiente a código.

Para el despliegue a través de código se crean diferentes componentes:

1. [VPC y Subnets dedicadas](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/vpc.tf)

2. [Instancia](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/main.tf)

3. [Equilibrio de carga](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/lb.tf)

4. [Grupos de seguridad](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/sg.tf)

5. [Llave SSH de la instancia](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/main.tf)

### Instrucciones para el despliegue

Para desplegar la infraestructura he creado un *script* en Python [deploy.py](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/deploy.py) que ejecuta los siguientes comandos de Terraform:
<pre><code>terraform init</code></pre>
<pre><code>terraform plan</code></pre>
<pre><code>terraform apply</code></pre>
El primer comando **crea** el directorio de trabajo, el segundo genera el **plan de ejecución** y el último realiza el **despliege** de los componentes AWS.
> La ejecución del *script* Python se debe hacer desde el directorio de trabajo que contenga los archivos .tf.

Para ejecutar el *script*:
<pre><code>python ./deploy.py</code></pre>

Una vez ejecutado se confirma con *yes*. El código Terraform generará una *llave SSH* en la **carpeta keys** que servirá para acceder por medio de SSH a la instancia WordPress.
> El usuario Linux de la instancia es *bitnami*.

Para **destruir** la infraestructura hay otro *script* Python [destroy.py](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/destroy.py). Se ejecuta con:
<pre><code>python ./destroy.py</code></pre>
> La destrucción de la infraestructura también borrará la llave SSH generada en AWS y en la carpeta keys.

Este *script* contiene el comando:
<pre><code>terraform destroy</code></pre>
que nos permite destruir la infraestructura desplegada.

Para que el balanceador reciba tráfico HTTPS hay que descomentar el listener HTTPS de [lb.tf](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/lb.tf) y añadir el certificado SSL en las variables locales de [main.tf](https://github.com/gnavio/aws-lb-wp/blob/main/terraform/main.tf).
<pre><code># Valores opcionales para listener HTTPS
# certificate_arn   = ""
# ssl_policy        = "ELBSecurityPolicy-2016-08"</code></pre>

## 📚 Recursos utilizados 
Estos han sido los recursos en los que me he apoyado para la realización de este proyecto.

[1] https://platzi.com/cursos/aws-cloud-practico/

[2] https://platzi.com/cursos/aws-cloud-computing/

[3] https://docs.aws.amazon.com/

[4] https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html

[5] https://www.youtube.com/watch?v=SLB_c_ayRMo

[6] https://registry.terraform.io/providers/hashicorp/aws/latest/docs
