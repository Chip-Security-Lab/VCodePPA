module mux_d_latch (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    input wire enable,
    output reg q
);
    wire selected_d;
    
    assign selected_d = d_inputs[select];
    
    always @* begin
        if (enable)
            q = selected_d;
    end
endmodule