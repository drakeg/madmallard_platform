# Generated scaffold migration
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    initial = True
    dependencies = []
    operations = [
        migrations.CreateModel(
            name='Business',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('slug', models.SlugField(unique=True)),
                ('public_name', models.CharField(max_length=120)),
                ('legal_name', models.CharField(blank=True, max_length=160)),
                ('tagline', models.CharField(blank=True, max_length=240)),
                ('primary_domain', models.CharField(blank=True, max_length=255)),
                ('theme_key', models.CharField(default='default', max_length=80)),
                ('template_key', models.CharField(default='default', max_length=80)),
                ('is_active', models.BooleanField(default=True)),
            ],
        ),
        migrations.CreateModel(
            name='Domain',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('hostname', models.CharField(max_length=255, unique=True)),
                ('is_primary', models.BooleanField(default=False)),
                ('business', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='domains', to='businesses.business')),
            ],
        ),
    ]
