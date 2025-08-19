//SystemVerilog
module matrix_switch #(parameter INPUTS=4, OUTPUTS=4, DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3,
    output reg [DATA_W-1:0] dout_0, dout_1, dout_2, dout_3
);
    // Intermediate signals for each input-to-output path
    reg [DATA_W-1:0] din0_to_out0, din0_to_out1, din0_to_out2, din0_to_out3;
    reg [DATA_W-1:0] din1_to_out0, din1_to_out1, din1_to_out2, din1_to_out3;
    reg [DATA_W-1:0] din2_to_out0, din2_to_out1, din2_to_out2, din2_to_out3;
    reg [DATA_W-1:0] din3_to_out0, din3_to_out1, din3_to_out2, din3_to_out3;

    // Route din_0 to appropriate output based on sel_0
    always @(*) begin
        din0_to_out0 = 'b0;
        din0_to_out1 = 'b0;
        din0_to_out2 = 'b0;
        din0_to_out3 = 'b0;
        
        case(sel_0)
            2'd0: din0_to_out0 = din_0;
            2'd1: din0_to_out1 = din_0;
            2'd2: din0_to_out2 = din_0;
            2'd3: din0_to_out3 = din_0;
        endcase
    end

    // Route din_1 to appropriate output based on sel_1
    always @(*) begin
        din1_to_out0 = 'b0;
        din1_to_out1 = 'b0;
        din1_to_out2 = 'b0;
        din1_to_out3 = 'b0;
        
        case(sel_1)
            2'd0: din1_to_out0 = din_1;
            2'd1: din1_to_out1 = din_1;
            2'd2: din1_to_out2 = din_1;
            2'd3: din1_to_out3 = din_1;
        endcase
    end

    // Route din_2 to appropriate output based on sel_2
    always @(*) begin
        din2_to_out0 = 'b0;
        din2_to_out1 = 'b0;
        din2_to_out2 = 'b0;
        din2_to_out3 = 'b0;
        
        case(sel_2)
            2'd0: din2_to_out0 = din_2;
            2'd1: din2_to_out1 = din_2;
            2'd2: din2_to_out2 = din_2;
            2'd3: din2_to_out3 = din_2;
        endcase
    end

    // Route din_3 to appropriate output based on sel_3
    always @(*) begin
        din3_to_out0 = 'b0;
        din3_to_out1 = 'b0;
        din3_to_out2 = 'b0;
        din3_to_out3 = 'b0;
        
        case(sel_3)
            2'd0: din3_to_out0 = din_3;
            2'd1: din3_to_out1 = din_3;
            2'd2: din3_to_out2 = din_3;
            2'd3: din3_to_out3 = din_3;
        endcase
    end

    // Combine all inputs to form the final outputs
    always @(*) begin
        dout_0 = din0_to_out0 | din1_to_out0 | din2_to_out0 | din3_to_out0;
        dout_1 = din0_to_out1 | din1_to_out1 | din2_to_out1 | din3_to_out1;
        dout_2 = din0_to_out2 | din1_to_out2 | din2_to_out2 | din3_to_out2;
        dout_3 = din0_to_out3 | din1_to_out3 | din2_to_out3 | din3_to_out3;
    end
endmodule