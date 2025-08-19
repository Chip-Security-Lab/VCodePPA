//SystemVerilog
module freq_divider(
    input wire clk_in, rst_n,
    input wire [15:0] div_ratio,
    input wire update_ratio,
    output reg clk_out
);
    localparam IDLE=1'b0, DIVIDE=1'b1;
    reg state, next;
    reg [15:0] counter_stage1, counter_stage2;
    reg [15:0] div_value_stage1, div_value_stage2;
    reg clk_out_stage1;
    
    // Stage 1: Update and Counter Logic
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter_stage1 <= 16'd0;
            div_value_stage1 <= 16'd2;
            clk_out_stage1 <= 1'b0;
        end else begin
            state <= next;
            
            if (update_ratio) begin
                if (div_ratio < 16'd2)
                    div_value_stage1 <= 16'd2;
                else
                    div_value_stage1 <= div_ratio;
            end
            
            case (state)
                IDLE: counter_stage1 <= 16'd0;
                DIVIDE: begin
                    counter_stage1 <= counter_stage1 + 16'd1;
                    if (counter_stage1 >= (div_value_stage1/2 - 1)) begin
                        counter_stage1 <= 16'd0;
                        clk_out_stage1 <= ~clk_out_stage1;
                    end
                end
            endcase
        end
    
    // Stage 2: Output Synchronization
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            counter_stage2 <= 16'd0;
            div_value_stage2 <= 16'd2;
            clk_out <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            div_value_stage2 <= div_value_stage1;
            clk_out <= clk_out_stage1;
        end
    
    // Next State Logic
    always @(*)
        case (state)
            IDLE: next = DIVIDE;
            DIVIDE: next = DIVIDE;
            default: next = IDLE;
        endcase
endmodule