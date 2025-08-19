//SystemVerilog
module crossbar_sync_4x4 (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output reg [7:0] out0, out1, out2, out3
);
    // Register inputs to reduce input-to-register delay
    reg [7:0] in0_reg, in1_reg, in2_reg, in3_reg;
    reg [1:0] sel0_reg, sel1_reg, sel2_reg, sel3_reg;
    
    // For retiming, create cross-path registers
    reg [7:0] in0_to_out0, in0_to_out1, in0_to_out2, in0_to_out3;
    reg [7:0] in1_to_out0, in1_to_out1, in1_to_out2, in1_to_out3;
    reg [7:0] in2_to_out0, in2_to_out1, in2_to_out2, in2_to_out3;
    reg [7:0] in3_to_out0, in3_to_out1, in3_to_out2, in3_to_out3;
    
    // Input registration stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {in0_reg, in1_reg, in2_reg, in3_reg} <= 32'b0;
            {sel0_reg, sel1_reg, sel2_reg, sel3_reg} <= 8'b0;
        end else begin
            in0_reg <= in0;
            in1_reg <= in1;
            in2_reg <= in2;
            in3_reg <= in3;
            sel0_reg <= sel0;
            sel1_reg <= sel1;
            sel2_reg <= sel2;
            sel3_reg <= sel3;
        end
    end
    
    // Retimed input-to-output path registers (moving registers from output to before combinational logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in0_to_out0 <= 8'b0;
            in0_to_out1 <= 8'b0;
            in0_to_out2 <= 8'b0;
            in0_to_out3 <= 8'b0;
            
            in1_to_out0 <= 8'b0;
            in1_to_out1 <= 8'b0;
            in1_to_out2 <= 8'b0;
            in1_to_out3 <= 8'b0;
            
            in2_to_out0 <= 8'b0;
            in2_to_out1 <= 8'b0;
            in2_to_out2 <= 8'b0;
            in2_to_out3 <= 8'b0;
            
            in3_to_out0 <= 8'b0;
            in3_to_out1 <= 8'b0;
            in3_to_out2 <= 8'b0;
            in3_to_out3 <= 8'b0;
        end else begin
            in0_to_out0 <= in0_reg;
            in0_to_out1 <= in0_reg;
            in0_to_out2 <= in0_reg;
            in0_to_out3 <= in0_reg;
            
            in1_to_out0 <= in1_reg;
            in1_to_out1 <= in1_reg;
            in1_to_out2 <= in1_reg;
            in1_to_out3 <= in1_reg;
            
            in2_to_out0 <= in2_reg;
            in2_to_out1 <= in2_reg;
            in2_to_out2 <= in2_reg;
            in2_to_out3 <= in2_reg;
            
            in3_to_out0 <= in3_reg;
            in3_to_out1 <= in3_reg;
            in3_to_out2 <= in3_reg;
            in3_to_out3 <= in3_reg;
        end
    end
    
    // Simplified multiplexer logic with pre-registered data paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {out0, out1, out2, out3} <= 32'b0;
        end else begin
            out0 <= (sel0_reg == 2'b00) ? in0_to_out0 : (sel0_reg == 2'b01) ? in1_to_out0 : 
                   (sel0_reg == 2'b10) ? in2_to_out0 : in3_to_out0;
                   
            out1 <= (sel1_reg == 2'b00) ? in0_to_out1 : (sel1_reg == 2'b01) ? in1_to_out1 : 
                   (sel1_reg == 2'b10) ? in2_to_out1 : in3_to_out1;
                   
            out2 <= (sel2_reg == 2'b00) ? in0_to_out2 : (sel2_reg == 2'b01) ? in1_to_out2 : 
                   (sel2_reg == 2'b10) ? in2_to_out2 : in3_to_out2;
                   
            out3 <= (sel3_reg == 2'b00) ? in0_to_out3 : (sel3_reg == 2'b01) ? in1_to_out3 : 
                   (sel3_reg == 2'b10) ? in2_to_out3 : in3_to_out3;
        end
    end
endmodule