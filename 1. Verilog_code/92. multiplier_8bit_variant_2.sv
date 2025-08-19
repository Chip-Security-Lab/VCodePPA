//SystemVerilog
module multiplier_8bit (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg product_valid
);

    // Pipeline stages
    reg [7:0] a_stage1, b_stage1;
    reg valid_stage1;
    
    reg [15:0] partial_product_stage2;
    reg valid_stage2;
    
    reg [15:0] final_product_stage3;
    reg valid_stage3;
    
    // State machine for control
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    
    // Stage 1: Input register and partial multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid && ready) begin
                a_stage1 <= a;
                b_stage1 <= b;
                valid_stage1 <= 1'b1;
            end else if (state == IDLE) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Partial product calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_product_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                partial_product_stage2 <= a_stage1 * b_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_product_stage3 <= 16'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                final_product_stage3 <= partial_product_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            product <= 16'b0;
            product_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        state <= BUSY;
                        ready <= 1'b0;
                    end
                    product_valid <= 1'b0;
                end
                BUSY: begin
                    if (valid_stage3) begin
                        state <= IDLE;
                        ready <= 1'b1;
                        product <= final_product_stage3;
                        product_valid <= 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule