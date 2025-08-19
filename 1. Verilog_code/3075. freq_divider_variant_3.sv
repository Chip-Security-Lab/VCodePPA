//SystemVerilog
module freq_divider(
    input wire clk_in,
    input wire rst_n,
    input wire [15:0] div_ratio,
    input wire valid,
    output wire ready,
    output reg clk_out
);
    localparam IDLE=1'b0, DIVIDE=1'b1;
    reg state, next;
    reg [15:0] counter;
    reg [15:0] div_value;
    reg ratio_updated;
    
    // Buffer registers for high fanout signals
    reg [15:0] counter_buf;
    reg [15:0] div_value_buf;
    reg state_buf;
    reg next_buf;
    reg ratio_updated_buf;
    
    // Two-stage buffer for critical path
    reg [15:0] counter_buf2;
    reg [15:0] div_value_buf2;
    reg state_buf2;
    reg next_buf2;
    
    assign ready = (state_buf2 == IDLE) || (state_buf2 == DIVIDE && counter_buf2 == 16'd0);
    
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            div_value <= 16'd2;
            clk_out <= 1'b0;
            ratio_updated <= 1'b0;
            
            counter_buf <= 16'd0;
            div_value_buf <= 16'd2;
            state_buf <= IDLE;
            next_buf <= IDLE;
            ratio_updated_buf <= 1'b0;
            
            counter_buf2 <= 16'd0;
            div_value_buf2 <= 16'd2;
            state_buf2 <= IDLE;
            next_buf2 <= IDLE;
        end else begin
            // First stage buffer
            counter_buf <= counter;
            div_value_buf <= div_value;
            state_buf <= state;
            next_buf <= next;
            ratio_updated_buf <= ratio_updated;
            
            // Second stage buffer
            counter_buf2 <= counter_buf;
            div_value_buf2 <= div_value_buf;
            state_buf2 <= state_buf;
            next_buf2 <= next_buf;
            
            state <= next_buf2;
            
            if (valid && ready) begin
                div_value <= (div_ratio < 16'd2) ? 16'd2 : div_ratio;
                ratio_updated <= 1'b1;
            end
            
            case (state_buf2)
                IDLE: begin
                    counter <= 16'd0;
                    if (ratio_updated_buf) begin
                        ratio_updated <= 1'b0;
                        state <= DIVIDE;
                    end
                end
                DIVIDE: begin
                    counter <= counter_buf2 + 16'd1;
                    if (counter_buf2 >= (div_value_buf2/2 - 1)) begin
                        counter <= 16'd0;
                        clk_out <= ~clk_out;
                    end
                end
            endcase
        end
    
    always @(*)
        case (state_buf2)
            IDLE: next = (ratio_updated_buf) ? DIVIDE : IDLE;
            DIVIDE: next = DIVIDE;
            default: next = IDLE;
        endcase
endmodule