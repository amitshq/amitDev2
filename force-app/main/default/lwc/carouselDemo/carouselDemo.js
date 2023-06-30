import { LightningElement } from 'lwc';

export default class CarouselDemo extends LightningElement {
    options = { autoScroll: true, autoScrollTime: 2 };
    items = [
        {
            image: 'https://images.pexels.com/photos/132037/pexels-photo-132037.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500',
            header: 'Landscape 1',
            description: 'Demo image for carousel.',
            href: 'https://images.pexels.com/photos/132037/pexels-photo-132037.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500'
        }, {
            video: 'https://www.youtube.com/embed/SLaWOkc3bC8',
            header: 'Video 1',
            description: 'Demo video for carousel.',
        },
        {
            video: 'https://player.vimeo.com/video/241135386',
            header: 'Video 2',
            description: 'Demo image for carousel.',
        }, {
            image: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjExMDk0fQ&w=1000&q=80',
            header: 'Landscape 4',
            description: 'Demo image for carousel.',
        },
        {
            image: 'https://cdn.cnn.com/cnnnext/dam/assets/190517091026-07-unusual-landscapes-travel.jpg',
            header: 'Landscape 5',
            description: 'Demo image for carousel.',
        }, {
            image: 'https://solablogdotcom.files.wordpress.com/2015/11/lake-district-1009459_1920.png?w=1134',
            header: 'Landscape 6',
            description: 'Demo image for carousel.',
        },
        {
            image: 'https://i.unu.edu/media/ourworld.unu.edu-en/article/8564/Champions_of_Cumbria_Human_Landscapes1.jpg',
            header: 'Landscape 7',
            description: 'Demo image for carousel.',
        }, {
            image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSVGWCqosuufmXUpuQDGpktXc2e1PaIB2K-cOhJBVEFOuP4hjWR&usqp=CAU',
            header: 'Landscape 8',
            description: 'Demo image for carousel.',
        }
    ]
}