module bidir_shift_reg #(parameter W = 16) (
    input clock, reset,
    input direction,     // 0: right, 1: left
    input ser_in,
    output ser_out
);
    reg [W-1:0] register;
    
    always @(posedge clock) begin
        if (reset)
            register <= 0;
        else if (direction)  // Left shift
            register <= {register[W-2:0], ser_in};
        else                 // Right shift
            register <= {ser_in, register[W-1:1]};
    end
    
    assign ser_out = direction ? register[W-1] : register[0];
endmodule