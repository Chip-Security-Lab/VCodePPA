//SystemVerilog
//IEEE 1364-2005
module timeout_shadow_reg #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire data_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Timeout counter - optimized bit width calculation
    localparam CNT_WIDTH = $clog2(TIMEOUT+1);
    reg [CNT_WIDTH-1:0] timeout_cnt;
    
    // Timeout flag for shadow register update
    wire timeout_flag;
    
    // 1's complement for subtraction
    wire [CNT_WIDTH-1:0] cnt_ones_complement;
    // Internal carries for two's complement subtraction
    wire [CNT_WIDTH:0] sub_carries;
    // Result of subtraction
    wire [CNT_WIDTH-1:0] cnt_next;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= {WIDTH{1'b0}};
        else if (data_valid)
            data_reg <= data_in;
    end
    
    // Generate 1's complement for subtraction
    assign cnt_ones_complement = ~1'b1;
    
    // Carry chain for two's complement subtraction
    assign sub_carries[0] = 1'b1; // Add 1 to 1's complement
    
    genvar i;
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : gen_sub
            assign cnt_next[i] = timeout_cnt[i] ^ cnt_ones_complement[i] ^ sub_carries[i];
            assign sub_carries[i+1] = (timeout_cnt[i] & cnt_ones_complement[i]) | 
                                     (timeout_cnt[i] & sub_carries[i]) | 
                                     (cnt_ones_complement[i] & sub_carries[i]);
        end
    endgenerate
    
    // Optimized timeout counter logic with binary two's complement subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_cnt <= {CNT_WIDTH{1'b0}};
        end else if (data_valid) begin
            timeout_cnt <= TIMEOUT;
        end else if (|timeout_cnt) begin  // Non-zero check using reduction OR
            timeout_cnt <= cnt_next;
        end
    end
    
    // Efficient timeout detection
    assign timeout_flag = (timeout_cnt == 1'b1);
    
    // Shadow register update when timeout occurs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (timeout_flag)
            shadow_out <= data_reg;
    end
endmodule