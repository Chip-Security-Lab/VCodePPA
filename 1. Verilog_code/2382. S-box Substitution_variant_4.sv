//SystemVerilog
//IEEE 1364-2005 Verilog
module sbox_substitution #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    enable,
    input  wire [ADDR_WIDTH-1:0]   addr_in,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg  [DATA_WIDTH-1:0]   data_out
);
    // S-box lookup memory
    reg [DATA_WIDTH-1:0] sbox [0:(1<<ADDR_WIDTH)-1];
    
    // Pipeline registers with increased pipeline depth
    reg                     enable_stage1;
    reg                     enable_stage2;
    reg                     enable_stage3;
    reg                     enable_stage4;
    reg [ADDR_WIDTH-1:0]    addr_stage1;
    reg [ADDR_WIDTH-1:0]    addr_stage2;
    reg [DATA_WIDTH-1:0]    data_stage1;
    reg [DATA_WIDTH-1:0]    data_stage2;
    reg [DATA_WIDTH-1:0]    data_stage3;
    reg [DATA_WIDTH-1:0]    sbox_data_stage1;
    reg [DATA_WIDTH-1:0]    sbox_data_stage2;
    reg [DATA_WIDTH/2-1:0]  partial_xor_high;
    reg [DATA_WIDTH/2-1:0]  partial_xor_low;
    
    // Stage 1: Register inputs and control signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable_stage1 <= 1'b0;
            addr_stage1   <= {ADDR_WIDTH{1'b0}};
            data_stage1   <= {DATA_WIDTH{1'b0}};
        end else begin
            enable_stage1 <= enable;
            addr_stage1   <= addr_in;
            data_stage1   <= data_in;
        end
    end
    
    // Stage 2: Pipeline the address lookup preparation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable_stage2 <= 1'b0;
            addr_stage2   <= {ADDR_WIDTH{1'b0}};
            data_stage2   <= {DATA_WIDTH{1'b0}};
        end else begin
            enable_stage2 <= enable_stage1;
            addr_stage2   <= addr_stage1;
            data_stage2   <= data_stage1;
        end
    end
    
    // Stage 3: S-box lookup and register the result
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sbox_data_stage1 <= {DATA_WIDTH{1'b0}};
            enable_stage3    <= 1'b0;
            data_stage3      <= {DATA_WIDTH{1'b0}};
        end else begin
            sbox_data_stage1 <= sbox[addr_stage2];
            enable_stage3    <= enable_stage2;
            data_stage3      <= data_stage2;
        end
    end
    
    // Stage 4: Register the lookup result again to further pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sbox_data_stage2 <= {DATA_WIDTH{1'b0}};
            enable_stage4    <= 1'b0;
        end else begin
            sbox_data_stage2 <= sbox_data_stage1;
            enable_stage4    <= enable_stage3;
        end
    end
    
    // Stage 5: Split XOR operation to two parts for better timing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            partial_xor_high <= {(DATA_WIDTH/2){1'b0}};
            partial_xor_low  <= {(DATA_WIDTH/2){1'b0}};
        end else if (enable_stage4) begin
            partial_xor_high <= sbox_data_stage2[DATA_WIDTH-1:DATA_WIDTH/2] ^ 
                               data_stage3[DATA_WIDTH-1:DATA_WIDTH/2];
            partial_xor_low  <= sbox_data_stage2[DATA_WIDTH/2-1:0] ^ 
                               data_stage3[DATA_WIDTH/2-1:0];
        end
    end
    
    // Stage 6: Final combination and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= {partial_xor_high, partial_xor_low};
        end
    end
    
endmodule