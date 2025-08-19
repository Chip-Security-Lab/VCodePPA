//SystemVerilog
module vector_ismu #(parameter VECTOR_WIDTH = 8)(
    input wire clk_i, rst_n_i,
    input wire [VECTOR_WIDTH-1:0] src_i,
    input wire [VECTOR_WIDTH-1:0] mask_i,
    input wire ack_i,
    output reg [VECTOR_WIDTH-1:0] vector_o,
    output reg valid_o
);
    reg [VECTOR_WIDTH-1:0] pending_r;
    wire [VECTOR_WIDTH-1:0] mask_complement;
    wire [VECTOR_WIDTH-1:0] masked_src;
    
    // 使用补码加法实现按位非操作：~mask_i = -mask_i - 1 = (~mask_i + 1) - 1 = ~mask_i
    assign mask_complement = (~mask_i + {{(VECTOR_WIDTH-1){1'b0}}, 1'b1}) - {{(VECTOR_WIDTH-1){1'b0}}, 1'b1};
    assign masked_src = src_i & mask_complement;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pending_r <= {VECTOR_WIDTH{1'b0}};
            vector_o <= {VECTOR_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else begin
            pending_r <= pending_r | masked_src;
            if (ack_i) begin
                pending_r <= {VECTOR_WIDTH{1'b0}};
                valid_o <= 1'b0;
            end else if (|pending_r) begin
                valid_o <= 1'b1;
                vector_o <= pending_r;
            end
        end
    end
endmodule