//SystemVerilog
// LFSR Generator Module
module lfsr_generator(
    input clk,
    input rst,
    input enable,
    output reg [15:0] lfsr1_out,
    output reg [15:0] lfsr2_out,
    output reg valid_out
);
    reg [15:0] lfsr1, lfsr2;
    wire fb1 = lfsr1[15] ^ lfsr1[14] ^ lfsr1[12] ^ lfsr1[3];
    wire fb2 = lfsr2[15] ^ lfsr2[13] ^ lfsr2[11] ^ lfsr2[7];
    
    always @(posedge clk) begin
        if (rst) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h1234;
            valid_out <= 1'b0;
        end else if (enable) begin
            lfsr1 <= {lfsr1[14:0], fb1};
            lfsr2 <= {lfsr2[14:0], fb2};
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
    
    assign lfsr1_out = lfsr1;
    assign lfsr2_out = lfsr2;
endmodule

// Gaussian Noise Generator Module
module gaussian_noise(
    input clk,
    input rst,
    input enable,
    output reg [7:0] noise_out,
    output reg valid_out
);
    // LFSR Generator Interface
    wire [15:0] lfsr1_out, lfsr2_out;
    wire lfsr_valid;
    
    // Pipeline Registers
    reg [15:0] lfsr1_stage2, lfsr2_stage2;
    reg valid_stage2;
    reg [7:0] sum_stage3;
    reg valid_stage3;
    
    // Instantiate LFSR Generator
    lfsr_generator lfsr_inst(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .lfsr1_out(lfsr1_out),
        .lfsr2_out(lfsr2_out),
        .valid_out(lfsr_valid)
    );
    
    // Pipeline Stage 2: Register LFSR outputs
    always @(posedge clk) begin
        if (rst) begin
            lfsr1_stage2 <= 16'h0;
            lfsr2_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
        end else begin
            lfsr1_stage2 <= lfsr1_out;
            lfsr2_stage2 <= lfsr2_out;
            valid_stage2 <= lfsr_valid;
        end
    end
    
    // Pipeline Stage 3: Gaussian approximation
    always @(posedge clk) begin
        if (rst) begin
            sum_stage3 <= 8'h80;
            valid_stage3 <= 1'b0;
        end else begin
            sum_stage3 <= {1'b0, lfsr2_stage2[7:1]} + {1'b0, lfsr1_stage2[7:1]};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output Stage
    always @(posedge clk) begin
        if (rst) begin
            noise_out <= 8'h80;
            valid_out <= 1'b0;
        end else begin
            noise_out <= sum_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule