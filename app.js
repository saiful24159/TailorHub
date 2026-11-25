/* TailorHub browser app — Supabase Auth + customer data forms.
   Requires supabase-config.js with the public project URL and anon/publishable key. */
(function(){
  const $ = (id) => document.getElementById(id);
  let client = null;
  let currentUser = null;
  const toast = (message) => {
    const node = $("toast");
    node.textContent = message;
    node.classList.add("show");
    setTimeout(() => node.classList.remove("show"), 3200);
  };
  const esc = (value) => String(value ?? "").replace(/[&<>"']/g, ch => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
  }[ch]));
  function configReady(){
    return window.TAILORHUB_SUPABASE_URL &&
      window.TAILORHUB_SUPABASE_ANON_KEY &&
      !window.TAILORHUB_SUPABASE_URL.includes("YOUR_PROJECT_ID") &&
      !window.TAILORHUB_SUPABASE_ANON_KEY.includes("YOUR_SUPABASE");
  }
  function field(label,id,type="text",placeholder=""){
    return '<div class="field"><label for="'+id+'">'+label+'</label><input id="'+id+'" type="'+type+'" placeholder="'+placeholder+'" required></div>';
  }
  function showConfigNotice(){
    const n=document.createElement("div");
    n.className="notice";
    n.style.margin="18px 0";
    n.innerHTML="<b>Database এখনো সংযুক্ত নয়।</b> Supabase Project URL ও public anon/publishable key বসালে Login, মাপ সংরক্ষণ এবং বিক্রেতা আবেদন চালু হবে।";
    document.querySelector("main.wrap").prepend(n);
  }
  function updateAccountButton(){
    const btn=document.querySelector("header .nav button");
    if(!btn) return;
    btn.textContent=currentUser ? "আমার অ্যাকাউন্ট / লগআউট" : "লগইন / অ্যাকাউন্ট";
  }
  async function init(){
    if(!configReady() || !window.supabase){
      showConfigNotice();
      return;
    }
    client=window.supabase.createClient(
      window.TAILORHUB_SUPABASE_URL,
      window.TAILORHUB_SUPABASE_ANON_KEY
    );
    const {data:{session}}=await client.auth.getSession();
    currentUser=session?.user || null;
    updateAccountButton();
    client.auth.onAuthStateChange((_event,session)=>{
      currentUser=session?.user || null;
      updateAccountButton();
    });
  }
  window.openForm=function(type,item=""){
    const titles={login:"লগইন / নতুন অ্যাকাউন্ট",measure:"আপনার মাপ সংরক্ষণ",custom:"পোশাক কাস্টমাইজ",seller:"বিক্রেতা হওয়ার আবেদন"};
    $("title").textContent=titles[type] || "তথ্য দিন";
    let markup="";
    if(type==="login"){
      markup='<p class="muted">ইমেইল ও পাসওয়ার্ড দিয়ে অ্যাকাউন্ট খুলুন অথবা লগইন করুন।</p>'+
        field("আপনার নাম","auth-name")+
        field("ইমেইল","auth-email","email","name@example.com")+
        field("পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)","auth-password","password")+
        '<div class="grid" style="grid-template-columns:1fr 1fr"><button id="signup-btn" type="button">নতুন অ্যাকাউন্ট</button><button id="login-btn" type="button">লগইন</button></div>'+
        '<button id="logout-btn" type="button" style="width:100%;margin-top:10px;background:#51465f">লগআউট</button>'+
        '<p class="muted" id="auth-help">নতুন অ্যাকাউন্ট খুললে ইমেইল যাচাই করতে হতে পারে।</p>';
    } else if(type==="measure"){
      markup='<p class="muted">ফিতা দিয়ে মাপ নিয়ে সেন্টিমিটারে লিখুন। সঠিক মাপের জন্য টেইলারের সঙ্গে যাচাই করুন।</p>'+
        field("মাপের নাম","measure-label","text","আমার মাপ")+
        field("বুক (সেমি)","measure-chest","number")+
        field("কোমর (সেমি)","measure-waist","number")+
        field("কাঁধ (সেমি)","measure-shoulder","number")+
        field("হাতা (সেমি)","measure-sleeve","number")+
        field("পোশাকের দৈর্ঘ্য (সেমি)","measure-length","number")+
        '<button id="save-measure" type="button" style="width:100%">মাপ সংরক্ষণ করুন</button>';
    } else if(type==="seller"){
      markup=field("দোকানের নাম","seller-shop")+
        field("মালিকের নাম","seller-owner")+
        field("মোবাইল নম্বর","seller-phone","tel","01XXXXXXXXX")+
        field("জেলা","seller-district")+
        '<div class="field"><label for="seller-description">দোকান সম্পর্কে</label><input id="seller-description" placeholder="আপনার কাজের ধরন"></div>'+
        '<button id="send-seller" type="button" style="width:100%">আবেদন জমা দিন</button>'+
        '<p class="muted">আবেদন Super Admin অনুমোদন না করা পর্যন্ত বিক্রেতা সুবিধা চালু হবে না।</p>';
    } else {
      markup='<p><b>'+esc(item)+'</b></p>'+
        '<div class="field"><label>কাপড়</label><select id="custom-fabric"><option>কটন</option><option>লিনেন</option><option>পলিকটন</option></select></div>'+
        '<div class="field"><label>রং</label><select id="custom-color"><option>কালো</option><option>সাদা</option><option>নীল</option><option>মেরুন</option></select></div>'+
        '<div class="field"><label>ফিটিং</label><select id="custom-fit"><option>Regular</option><option>Slim</option><option>Loose</option></select></div>'+
        '<div class="notice">কাস্টমাইজেশন পছন্দ এখন এই ব্রাউজারে সাময়িকভাবে রাখা হচ্ছে। বাস্তব অর্ডার/মূল্য নির্ধারণ এখনো চালু হয়নি।</div>'+
        '<button id="save-custom" type="button" style="width:100%">পছন্দ সংরক্ষণ</button>';
    }
    $("form").innerHTML=markup;
    $("modal").classList.add("show");
    if(type==="login") bindAuth();
    if(type==="measure") $("save-measure").addEventListener("click",saveMeasurement);
    if(type==="seller") $("send-seller").addEventListener("click",applySeller);
    if(type==="custom") $("save-custom").addEventListener("click",()=>{
      const data={product:item,fabric:$("custom-fabric").value,color:$("custom-color").value,fit:$("custom-fit").value};
      localStorage.setItem("tailorhub-customization",JSON.stringify(data));
      toast("আপনার পছন্দ এই ডিভাইসে সংরক্ষণ হয়েছে।");
      closeForm();
    });
  };
  function bindAuth(){
    $("signup-btn").addEventListener("click",async()=>{
      if(!client) return toast("আগে Supabase সংযোগ করতে হবে।");
      const name=$("auth-name").value.trim(),email=$("auth-email").value.trim(),password=$("auth-password").value;
      if(!name||!email||password.length<6) return toast("নাম, সঠিক ইমেইল ও কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।");
      const {error}=await client.auth.signUp({email,password,options:{data:{full_name:name}}});
      if(error) return toast(error.message);
      $("auth-help").textContent="অ্যাকাউন্ট তৈরির অনুরোধ হয়েছে। ইমেইল যাচাইয়ের নির্দেশনা দেখুন।";
      toast("অ্যাকাউন্ট তৈরির অনুরোধ পাঠানো হয়েছে।");
    });
    $("login-btn").addEventListener("click",async()=>{
      if(!client) return toast("আগে Supabase সংযোগ করতে হবে।");
      const email=$("auth-email").value.trim(),password=$("auth-password").value;
      const {error}=await client.auth.signInWithPassword({email,password});
      if(error) return toast(error.message);
      toast("লগইন সফল হয়েছে।");
      closeForm();
    });
    $("logout-btn").addEventListener("click",async()=>{
      if(!client) return;
      const {error}=await client.auth.signOut();
      if(error) return toast(error.message);
      toast("লগআউট হয়েছে।");
      closeForm();
    });
  }
  async function requireUser(){
    if(!client) {toast("Supabase এখনো সংযুক্ত নয়।");return false;}
    if(!currentUser){toast("প্রথমে লগইন করুন।");openForm("login");return false;}
    return true;
  }
  async function saveMeasurement(){
    if(!await requireUser()) return;
    const values={};
    const fields={chest:"measure-chest",waist:"measure-waist",shoulder:"measure-shoulder",sleeve:"measure-sleeve",garment_length:"measure-length"};
    for(const [key,id] of Object.entries(fields)){
      const value=$(id).value;
      if(value) values[key]=Number(value);
    }
    if(!Object.keys(values).length || Object.values(values).some(v=>!Number.isFinite(v)||v<=0||v>300)){
      return toast("সঠিক মাপ লিখুন (সেন্টিমিটারে)।");
    }
    const {error}=await client.from("measurements").insert({
      customer_id:currentUser.id,
      label:$("measure-label").value.trim()||"আমার মাপ",
      unit:"cm",values,source:"manual"
    });
    if(error) return toast("মাপ সংরক্ষণ হয়নি: "+error.message);
    toast("আপনার মাপ নিরাপদভাবে সংরক্ষিত হয়েছে।");
    closeForm();
  }
  async function applySeller(){
    if(!await requireUser()) return;
    const row={
      user_id:currentUser.id,
      shop_name:$("seller-shop").value.trim(),
      description:$("seller-description").value.trim(),
      district:$("seller-district").value.trim(),
      phone:$("seller-phone").value.trim(),
      status:"pending"
    };
    if(!row.shop_name||!row.district||!row.phone) return toast("দোকানের নাম, জেলা ও মোবাইল নম্বর দিন।");
    const {error}=await client.from("seller_profiles").insert(row);
    if(error) return toast("আবেদন জমা হয়নি: "+error.message);
    toast("বিক্রেতা আবেদন জমা হয়েছে। অনুমোদনের অপেক্ষায় থাকুন।");
    closeForm();
  }
  window.closeForm=function(){$("modal").classList.remove("show");};
  window.toastMsg=toast;
  document.addEventListener("DOMContentLoaded",()=>{
    const modal=$("modal");
    modal.addEventListener("click",e=>{if(e.target===modal)closeForm();});
    init().catch(e=>toast("সংযোগে সমস্যা: "+e.message));
  });
})();