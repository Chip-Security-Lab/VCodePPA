//SystemVerilog
module hamming_encoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  data_in,
    input  wire        data_valid,
    output reg  [6:0]  encoded_out,
    output reg         data_ready
);
    // Internal registers for pipelining
    reg [3:0] data_reg;
    reg [2:0] parity_reg;
    
    // Data path registers
    reg d0_reg, d1_reg, d2_reg, d3_reg;
    reg p1_reg, p2_reg, p4_reg;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 4'b0;
            data_ready <= 1'b0;
        end else begin
            if (data_valid) begin
                data_reg <= data_in;
                data_ready <= 1'b1;
            end else begin
                data_ready <= 1'b0;
            end
        end
    end
    
    // Stage 2: Data extraction and parity calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0_reg <= 1'b0;
            d1_reg <= 1'b0;
            d2_reg <= 1'b0;
            d3_reg <= 1'b0;
            p1_reg <= 1'b0;
            p2_reg <= 1'b0;
            p4_reg <= 1'b0;
        end else begin
            if (data_valid) begin
                // Extract data bits
                d0_reg <= data_reg[0];
                d1_reg <= data_reg[1];
                d2_reg <= data_reg[2];
                d3_reg <= data_reg[3];
                
                // Calculate parity bits
                p1_reg <= data_reg[0] ^ data_reg[1] ^ data_reg[3];
                p2_reg <= data_reg[0] ^ data_reg[2] ^ data_reg[3];
                p4_reg <= data_reg[1] ^ data_reg[2] ^ data_reg[3];
            end
        end
    end
    
    // Stage 3: Output encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
        end else begin
            if (data_valid) begin
                // Hamming code organization: p1,p2,d1,p4,d2,d3,d4
                encoded_out <= {d3_reg, d2_reg, d1_reg, p4_reg, d0_reg, p2_reg, p1_reg};
            end
        end
    end
endmodule