# Generated scaffold migration
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    initial = True
    dependencies = [('businesses', '0001_initial')]
    operations = [
        migrations.CreateModel(
            name='Page',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('slug', models.SlugField()),
                ('title', models.CharField(max_length=200)),
                ('body', models.TextField(blank=True)),
                ('is_published', models.BooleanField(default=True)),
                ('business', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='pages', to='businesses.business')),
            ],
            options={'unique_together': {('business', 'slug')}},
        ),
    ]
