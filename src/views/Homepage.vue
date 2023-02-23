<template>
  <div class="home">
    <nav-bar/>
    <Main/>
    <FooterComp/>
  </div>
</template>

<script>
// @ is an alias to /src
import Main from '@/components/homepage/Main.vue'
import NavBar from "../components/general/NavBar";
import FooterComp from "../components/general/FooterComp";

export default {
  name: 'Homepage',
  components: {
    FooterComp,
    NavBar,
    Main,
  }
}
</script>
