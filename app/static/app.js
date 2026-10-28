async function load() {
  const version = await (await fetch('/version')).json();
  document.querySelector('#version').textContent = `Sürüm ${version.version} · Kaynak ${version.commit}`;
  const data = await (await fetch('/api/courses')).json();
  document.querySelector('#courses').replaceChildren();
  const select = document.querySelector('#course');
  const previous = select.value;
  select.replaceChildren();
  for (const course of data.courses) {
    const li = document.createElement('li');
    li.textContent = `${course.id} — ${course.name} (${course.enrolled}/${course.capacity})`;
    document.querySelector('#courses').append(li);
    const option = document.createElement('option');
    option.value = course.id; option.textContent = course.name; select.append(option);
  }
  if (previous) select.value = previous;
}
document.querySelector('#form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const result = document.querySelector('#result');
  try {
    const response = await fetch('/api/enrollments', {
      method: 'POST',
      headers: {'Content-Type': 'application/json', 'Authorization': `Bearer ${document.querySelector('#token').value}`},
      body: JSON.stringify({student_id: document.querySelector('#student').value, course_id: document.querySelector('#course').value})
    });
    const data = await response.json();
    result.textContent = response.ok ? `Kayıt oluşturuldu: ${data.student_id} / ${data.course_id}` : data.error;
    await load();
  } catch (_) { result.textContent = 'Hizmete erişilemedi.'; }
});
load().catch(() => { document.querySelector('#version').textContent = 'Hizmete erişilemedi.'; });
