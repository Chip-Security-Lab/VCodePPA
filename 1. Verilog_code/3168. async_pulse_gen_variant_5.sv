//SystemVerilog
module async_pulse_gen(
    input data_in,
    input reset,
    output pulse_out
);
    reg data_delayed;
    
    always @(posedge data_in or posedge reset) begin
        if (reset)
            data_delayed <= 1'b0;
        else
            data_delayed <= 1'b1;
    end
    
    assign pulse_out = data_in & ~data_delayed;
endmodule