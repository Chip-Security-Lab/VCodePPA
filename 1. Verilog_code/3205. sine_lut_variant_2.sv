//SystemVerilog
module sine_lut(
    input clk,
    input rst_n,
    input [3:0] addr_step,
    output reg [7:0] sine_out
);
    // Pipeline stage 1: Address calculation
    reg [7:0] addr_stage1;
    reg [7:0] addr_stage2;
    reg [3:0] addr_step_reg;
    
    // Pipeline stage 2: Memory access
    reg [7:0] sine_data_stage3;
    
    // Sine lookup table
    reg [7:0] sine_table [0:15];
    
    initial begin
        sine_table[0] = 8'd128;
        sine_table[1] = 8'd176;
        sine_table[2] = 8'd218;
        sine_table[3] = 8'd245;
        sine_table[4] = 8'd255;
        sine_table[5] = 8'd245;
        sine_table[6] = 8'd218;
        sine_table[7] = 8'd176;
        sine_table[8] = 8'd128;
        sine_table[9] = 8'd79;
        sine_table[10] = 8'd37;
        sine_table[11] = 8'd10;
        sine_table[12] = 8'd0;
        sine_table[13] = 8'd10;
        sine_table[14] = 8'd37;
        sine_table[15] = 8'd79;
    end
    
    // Stage 1: Register input and prepare address calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_step_reg <= 4'd0;
            addr_stage1 <= 8'd0;
        end
        else begin
            addr_step_reg <= addr_step;
            addr_stage1 <= addr_stage1 + {4'b0000, addr_step_reg};
        end
    end
    
    // Stage 2: Calculate actual table address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 8'd0;
        end
        else begin
            addr_stage2 <= addr_stage1;
        end
    end
    
    // Stage 3: Memory lookup
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sine_data_stage3 <= 8'd0;
        end
        else begin
            sine_data_stage3 <= sine_table[addr_stage2[7:4]];
        end
    end
    
    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sine_out <= 8'd0;
        end
        else begin
            sine_out <= sine_data_stage3;
        end
    end
endmodule