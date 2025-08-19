module mux_divider (
    input main_clock, reset, enable,
    input [1:0] select,
    output out_clock
);
    reg [3:0] divider;
    wire div2, div4, div8, div16;
    
    always @(posedge main_clock or posedge reset) begin
        if (reset)
            divider <= 4'b0000;
        else if (enable)
            divider <= divider + 1'b1;
    end
    
    assign div2 = divider[0];
    assign div4 = divider[1];
    assign div8 = divider[2];
    assign div16 = divider[3];
    
    assign out_clock = (select == 2'b00) ? div2 :
                       (select == 2'b01) ? div4 :
                       (select == 2'b10) ? div8 : div16;
endmodule