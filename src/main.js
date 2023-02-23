import Vue from 'vue'
import App from './App.vue'
import router from './router'
import { BootstrapVue, BootstrapVueIcons } from 'bootstrap-vue'
import { library } from '@fortawesome/fontawesome-svg-core';
import { faCircle, faLanguage, faCheck, faArrowRight, faEnvelope } from '@fortawesome/free-solid-svg-icons';
import { faYoutube, faMedium, faFacebook, faTelegramPlane, faTwitter, faReddit, faDiscord, faInstagram, faTiktok } from '@fortawesome/free-brands-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';

library.add(faCircle, faArrowRight, faYoutube, faMedium, faEnvelope, faFacebook, faLanguage, faTwitter, faTelegramPlane, faReddit,faDiscord, faInstagram, faTiktok, faCheck );

Vue.component('font-awesome-icon', FontAwesomeIcon);

import './assets/css/home.scss'

// Make BootstrapVue available throughout your project
Vue.use(BootstrapVue)
Vue.use(BootstrapVueIcons)

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
