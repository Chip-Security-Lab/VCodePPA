//SystemVerilog
module onehot_input_decoder(
    input [7:0] onehot_in,
    output reg [2:0] binary_out,
    output reg valid
);
    
    always @(*) begin
        binary_out = 3'b000;
        valid = 1'b0;
        
        if (onehot_in[0]) begin
            binary_out = 3'b000;
            valid = 1'b1;
        end
        
        if (onehot_in[1]) begin
            binary_out = 3'b001;
            valid = 1'b1;
        end
        
        if (onehot_in[2]) begin
            binary_out = 3'b010;
            valid = 1'b1;
        end
        
        if (onehot_in[3]) begin
            binary_out = 3'b011;
            valid = 1'b1;
        end
        
        if (onehot_in[4]) begin
            binary_out = 3'b100;
            valid = 1'b1;
        end
        
        if (onehot_in[5]) begin
            binary_out = 3'b101;
            valid = 1'b1;
        end
        
        if (onehot_in[6]) begin
            binary_out = 3'b110;
            valid = 1'b1;
        end
        
        if (onehot_in[7]) begin
            binary_out = 3'b111;
            valid = 1'b1;
        end
    end
endmodule