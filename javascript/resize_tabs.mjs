function resize_tabs()
{

    if (tab_container.length > 7)
    {

        let new_tab_width = tab_holder.getBoundingClientRect().width / tab_container.length;

        for (let i in tab_container) 
        {
            let close_button = tab_container[i].getElementsByClassName("close_button")[0]
            let open_page_button = tab_container[i].getElementsByClassName("open_page_button")[0]
    
            tab_container[i].style.width = new_tab_width + "px";
            open_page_button.style.width = new_tab_width + "px";

            if (close_button.style.width > new_tab_width)
            {

                close_button.style.width = new_tab_width + "px";

            }
            else
            {

                close_button.style.width = 0.3 * tab_height;

            }
    
        };

    }

}

export {resize_tabs}