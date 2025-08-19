//SystemVerilog
module multiplier_shift (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg product_valid
);

    reg [15:0] product_reg;
    reg [2:0] state;
    reg [2:0] counter;
    
    // Buffer registers for high fanout signals
    reg [7:0] a_buf;
    reg [7:0] b_buf;
    reg [2:0] counter_buf;
    reg [15:0] product_reg_buf;
    reg valid_buf;
    reg ready_buf;
    
    localparam IDLE = 3'd0;
    localparam CALC = 3'd1;
    localparam DONE = 3'd2;
    
    // First stage: Buffer input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf <= 8'd0;
            b_buf <= 8'd0;
            valid_buf <= 1'b0;
            ready_buf <= 1'b1;
        end else begin
            a_buf <= a;
            b_buf <= b;
            valid_buf <= valid;
            ready_buf <= ready;
        end
    end
    
    // Main state machine with buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            counter <= 3'd0;
            product_reg <= 16'd0;
            ready <= 1'b1;
            product_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    product_valid <= 1'b0;
                    if (valid_buf && ready_buf) begin
                        state <= CALC;
                        counter <= 3'd0;
                        product_reg <= 16'd0;
                        ready <= 1'b0;
                    end
                end
                
                CALC: begin
                    // Buffer counter and product_reg for reduced fanout
                    counter_buf <= counter;
                    product_reg_buf <= product_reg;
                    
                    if (counter_buf < 3'd7) begin
                        if (b_buf[counter_buf]) begin
                            product_reg <= product_reg_buf + (a_buf << counter_buf);
                        end
                        counter <= counter_buf + 1;
                    end else begin
                        state <= DONE;
                        product <= product_reg;
                        product_valid <= 1'b1;
                    end
                end
                
                DONE: begin
                    product_valid <= 1'b0;
                    state <= IDLE;
                    ready <= 1'b1;
                end
            endcase
        end
    end
endmodule