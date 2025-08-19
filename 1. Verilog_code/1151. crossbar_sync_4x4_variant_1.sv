//SystemVerilog
//IEEE 1364-2005
module crossbar_sync_4x4 (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    input wire valid_in,
    output wire valid_out,
    output reg [7:0] out0, out1, out2, out3
);
    // Pipeline stage 1 registers - input and selection registration
    reg [7:0] in0_stage1, in1_stage1, in2_stage1, in3_stage1;
    reg [1:0] sel0_stage1, sel1_stage1, sel2_stage1, sel3_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers - intermediate mux results
    reg [7:0] out0_stage2, out1_stage2, out2_stage2, out3_stage2;
    reg valid_stage2;
    
    // Stage 1: Register inputs - split into multiple always blocks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in0_stage1 <= 8'b0;
            in1_stage1 <= 8'b0;
            in2_stage1 <= 8'b0;
            in3_stage1 <= 8'b0;
        end else begin
            in0_stage1 <= in0;
            in1_stage1 <= in1;
            in2_stage1 <= in2;
            in3_stage1 <= in3;
        end
    end
    
    // Register selection signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel0_stage1 <= 2'b0;
            sel1_stage1 <= 2'b0;
            sel2_stage1 <= 2'b0;
            sel3_stage1 <= 2'b0;
        end else begin
            sel0_stage1 <= sel0;
            sel1_stage1 <= sel1;
            sel2_stage1 <= sel2;
            sel3_stage1 <= sel3;
        end
    end
    
    // Register valid signal for stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform mux operations - one always block per output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_stage2 <= 8'b0;
        end else begin
            case (sel0_stage1)
                2'b00: out0_stage2 <= in0_stage1;
                2'b01: out0_stage2 <= in1_stage1;
                2'b10: out0_stage2 <= in2_stage1;
                2'b11: out0_stage2 <= in3_stage1;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out1_stage2 <= 8'b0;
        end else begin
            case (sel1_stage1)
                2'b00: out1_stage2 <= in0_stage1;
                2'b01: out1_stage2 <= in1_stage1;
                2'b10: out1_stage2 <= in2_stage1;
                2'b11: out1_stage2 <= in3_stage1;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out2_stage2 <= 8'b0;
        end else begin
            case (sel2_stage1)
                2'b00: out2_stage2 <= in0_stage1;
                2'b01: out2_stage2 <= in1_stage1;
                2'b10: out2_stage2 <= in2_stage1;
                2'b11: out2_stage2 <= in3_stage1;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out3_stage2 <= 8'b0;
        end else begin
            case (sel3_stage1)
                2'b00: out3_stage2 <= in0_stage1;
                2'b01: out3_stage2 <= in1_stage1;
                2'b10: out3_stage2 <= in2_stage1;
                2'b11: out3_stage2 <= in3_stage1;
            endcase
        end
    end
    
    // Register valid signal for stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final output registration - one always block per output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0 <= 8'b0;
        end else begin
            out0 <= out0_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out1 <= 8'b0;
        end else begin
            out1 <= out1_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out2 <= 8'b0;
        end else begin
            out2 <= out2_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out3 <= 8'b0;
        end else begin
            out3 <= out3_stage2;
        end
    end
    
    // Valid output signal
    reg valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end
    
    assign valid_out = valid_stage3;
    
endmodule