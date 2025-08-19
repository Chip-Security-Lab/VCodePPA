module async_pulse_gen(
    input data_in,
    input reset,
    output pulse_out
);
    reg data_delayed;
    
    always @(data_in or reset) begin
        if (reset)
            data_delayed = 1'b0;
        else
            data_delayed = data_in;
    end
    
    assign pulse_out = data_in & ~data_delayed;
endmodule