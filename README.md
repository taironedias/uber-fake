
### uber-fake for iOS
Creating a uber fake app for iOS learning.

Abaixo apresentamos algumas telas do desenvolvimento realizado. Algumas regras de negócio necessária para o funcionamento correto de app semelhante ao Uber, não foi considerado. O objetivo desse desenvolvimento, foi para o aprendizado. Reforçando assim o conhecimento de Mapas, Firebase, Permissões, UITableViewController, entre outros.

##### # Tela inicial > Tela de cadastro > Tela de login
Antes da tela inicial tem o LauchScreen, com apenas a logo Uber.
<table>
  <tr>
    <th> 
        <img src="/prints/telainicial.png" width="250" height="445">
    <th>
        <img src="/prints/telacadastro.png" width="250" height="445">
    </th>
    <th>
        <img src="/prints/telalogin.png" width="250" height="445">
    </th>
  </tr>
</table>


##### # App do passageiro
Nessa tela, o passageiro deve informar o local (em texto) para onde deseja ir. Uma vez que o inseriu o local, o app verifica e exibe a informação resgatada pelo ``CLGeocoder().geocodeAddressString``. Se o local estiver correto o passageiro pode Confirmar e assim chamar o Uber, caso contrário, poderás editar e tentar novamente!

<table>
  <tr>
    <th> 
        <img src="/prints/passageiro1.png" width="250" height="445"> </th>
    <th>
        <img src="/prints/passageiro2.png" width="250" height="445">
    </th>
  </tr>
</table>

##### # App do motorista

Quando uma soliciação é realizada, no perfil de qualquer motorista aparece as solicitações de corrida. E a distância que o motorista está do passageiro. Quando o motorista escolhe alguma corrida, ele é redirecionado para a tela que contém o mapa e obtém informações para do destino daquele passageiro.

<table>
  <tr>
    <th> 
        <img src="/prints/motorista.png" width="250" height="445">
    <th>
        <img src="/prints/motorista2.png" width="250" height="445">
    </th>
  </tr>
</table>


##### # App do passageiro e motorista

* Quando o motorista aceita a corrida o status é atualizado para ir pegar o passageiro em ambos o sistema, também, o mapa é atualizado mostrando o local do motorista e o local do passageiro.
<table>
  <tr>
    <th> 
        <img src="/prints/passageiro-1.png" width="250" height="445">
    <th>
        <img src="/prints/motorista-1.png" width="250" height="445">
    </th>
  </tr>
</table>

* Quando o motorista é bem próximo do passageiro, ele tem a opção de iniciar a viagem. Para o passageiro, não há nenhuma mudança significativa, com exceção da unidade de Km para metros.
<table>
  <tr>
    <th> 
        <img src="/prints/passageiro-2.png" width="250" height="445">
    <th>
        <img src="/prints/motorista-2.png" width="250" height="445">
    </th>
  </tr>
</table>

* O motorista aceitando a viagem, o status em ambos os sistemas mudam para em viagem. O mapa é atualizado para o local de partida e de destino.
<table>
  <tr>
    <th> 
        <img src="/prints/passageiro-3.png" width="250" height="445">
    <th>
        <img src="/prints/motorista-3.png" width="250" height="445">
    </th>
  </tr>
</table>

* Ao chegar no destino, o motorista pode finalizar a viagem e o sistema calcula o valor da corrida, exibindo para ambos os usuários.
<table>
  <tr>
    <th> 
        <img src="/prints/passageiro-4.png" width="250" height="445">
    <th>
        <img src="/prints/motorista-4.png" width="250" height="445">
    </th>
  </tr>
</table>

##### # Tempo de desenvolvimento
O tempo de desenvolvimento desse projeto foi de aproximadamente 15h55min, segundo os dados coletos pelo Wakatime.
<img src="/prints/wakatime.png" >
    

Percebam que o app deveria: 
* o endereço de destino poderia ser inserido um pin no mapa, em vez de apenas digitar o endereço;
* calcular o preço da corrida antes do passageiro chamar o Uber;
* calcular o preço da corrida conforme a distância;
* apresentar um tratamento de distância entre o local atual e o destino, e assim, permitir que o motorista finalize a viagem, entre outros.

Mas novamente, esse foi um projeto desenvolvido para fins de estudo e prática da linguagem e componentes do Swift/iOS.
=)
