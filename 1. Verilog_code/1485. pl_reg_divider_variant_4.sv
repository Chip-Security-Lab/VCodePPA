//SystemVerilog
module pl_reg_divider #(parameter W=8, DIV=4) (
    input clk, rst,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // Newton-Raphson Iteration divisor with pipelined stages
    reg [2:0] iteration_count;
    reg [W-1:0] x, x_next;
    reg [W-1:0] dividend;
    
    // Pipeline registers for breaking long combinational paths
    reg [W-1:0] x_pipe;
    reg [2*W-1:0] temp_product, temp_product_pipe;
    reg [W-1:0] two_minus_dx, two_minus_dx_pipe;
    
    reg div_start, div_done;
    
    localparam IDLE = 2'b00;
    localparam CALCULATE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state;
    reg [DIV-1:0] counter;
    
    // Sub-states to manage pipeline stages
    localparam MULT1 = 3'b000;
    localparam SUB = 3'b001;
    localparam MULT2 = 3'b010;
    localparam SHIFT = 3'b011;
    localparam ITER_DONE = 3'b100;
    
    reg [2:0] calc_stage;
    
    // State machine for pipelined division process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            data_out <= 0;
            div_done <= 0;
            div_start <= 0;
            iteration_count <= 0;
            x <= 0;
            x_pipe <= 0;
            dividend <= 0;
            temp_product <= 0;
            temp_product_pipe <= 0;
            two_minus_dx <= 0;
            two_minus_dx_pipe <= 0;
            calc_stage <= MULT1;
        end else begin
            counter <= counter + 1;
            
            case (state)
                IDLE: begin
                    if (&counter) begin
                        dividend <= data_in;
                        div_start <= 1;
                        x <= {1'b1, {(W-1){1'b0}}}; // Initial guess (1.0 in fixed point)
                        iteration_count <= 0;
                        state <= CALCULATE;
                        calc_stage <= MULT1;
                    end
                end
                
                CALCULATE: begin
                    div_start <= 0;
                    
                    if (iteration_count < 3) begin // 3 iterations for 8-bit precision
                        case (calc_stage)
                            MULT1: begin
                                // Pipeline stage 1: Calculate x * dividend (fixed-point multiplication)
                                temp_product <= x * dividend;
                                x_pipe <= x; // Store x for later use
                                calc_stage <= SUB;
                            end
                            
                            SUB: begin
                                // Pipeline stage 2: Calculate 2 - (x * dividend)
                                temp_product_pipe <= temp_product; // Store intermediate result
                                two_minus_dx <= (2 << (W-2)) - temp_product[2*W-2:W-1];
                                calc_stage <= MULT2;
                            end
                            
                            MULT2: begin
                                // Pipeline stage 3: Calculate x * (2 - dividend * x)
                                two_minus_dx_pipe <= two_minus_dx; // Store intermediate result
                                temp_product <= x_pipe * two_minus_dx;
                                calc_stage <= SHIFT;
                            end
                            
                            SHIFT: begin
                                // Pipeline stage 4: Final shift for this iteration
                                x <= temp_product >> (W-1);
                                calc_stage <= ITER_DONE;
                            end
                            
                            ITER_DONE: begin
                                // Prepare for next iteration
                                iteration_count <= iteration_count + 1;
                                calc_stage <= MULT1;
                            end
                            
                            default: calc_stage <= MULT1;
                        endcase
                    end else begin
                        div_done <= 1;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    if (div_done) begin
                        // Final result: 1/dividend
                        data_out <= x;
                        div_done <= 0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule