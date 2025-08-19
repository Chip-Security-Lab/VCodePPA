//SystemVerilog
module bidir_shift_reg #(parameter W = 16) (
    input wire clock, reset,
    input wire direction,     // 0: right, 1: left
    input wire ser_in,
    output wire ser_out
);
    reg [W-1:0] register;
    reg output_bit;
    
    always @(posedge clock) begin
        if (reset)
            register <= {W{1'b0}};
        else begin
            if (direction) begin  // Left shift
                register <= {register[W-2:0], ser_in};
            end else begin        // Right shift
                register <= {ser_in, register[W-1:1]};
            end
        end
    end
    
    always @(*) begin
        if (direction) begin
            output_bit = register[W-1];
        end else begin
            output_bit = register[0];
        end
    end
    
    assign ser_out = output_bit;
endmodule