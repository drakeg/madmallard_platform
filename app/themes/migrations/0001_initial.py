# Generated scaffold migration
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    initial = True
    dependencies = [('businesses', '0001_initial')]
    operations = [
        migrations.CreateModel(
            name='ThemeSetting',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('primary_color', models.CharField(default='#1f2937', max_length=20)),
                ('accent_color', models.CharField(default='#f59e0b', max_length=20)),
                ('font_family', models.CharField(default='system-ui', max_length=120)),
                ('custom_css', models.TextField(blank=True)),
                ('business', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='theme', to='businesses.business')),
            ],
        ),
    ]
