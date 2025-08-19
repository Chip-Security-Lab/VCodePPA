//SystemVerilog
// Top level module
module multiplier_pipeline (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    output ready_in,
    output [15:0] product,
    output valid_out,
    input ready_out
);

    // Internal signals
    wire [15:0] calc_result;
    wire calc_valid;
    wire calc_ready;
    
    // State controller instance
    state_controller state_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .calc_valid(calc_valid),
        .ready_in(ready_in),
        .valid_out(valid_out)
    );

    // Calculation pipeline instance  
    calc_pipeline calc_pipe (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .valid_in(valid_in),
        .ready_out(calc_ready),
        .result(calc_result),
        .valid_out(calc_valid)
    );

    // Output register
    reg [15:0] product_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product_reg <= 16'b0;
        else if (calc_valid)
            product_reg <= calc_result;
    end

    assign product = product_reg;

endmodule

// State controller module
module state_controller (
    input clk,
    input rst_n,
    input valid_in,
    input ready_out,
    input calc_valid,
    output reg ready_in,
    output reg valid_out
);

    reg [1:0] state;
    reg [1:0] next_state;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam WAIT = 2'b10;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_in)
                    next_state = CALC;
            end
            CALC: begin
                if (calc_valid)
                    next_state = WAIT;
            end
            WAIT: begin
                if (ready_out)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    ready_in <= ~valid_in;
                    valid_out <= 1'b0;
                end
                CALC: begin
                    ready_in <= 1'b0;
                    valid_out <= calc_valid;
                end
                WAIT: begin
                    ready_in <= 1'b0;
                    valid_out <= ~ready_out;
                end
                default: begin
                    ready_in <= 1'b1;
                    valid_out <= 1'b0;
                end
            endcase
        end
    end

endmodule

// Calculation pipeline module
module calc_pipeline (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    input ready_out,
    output reg [15:0] result,
    output reg valid_out
);

    reg [15:0] p1, p2, p3;
    reg [7:0] a_reg, b_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            p1 <= 16'b0;
            p2 <= 16'b0;
            p3 <= 16'b0;
            result <= 16'b0;
            valid_out <= 1'b0;
        end
        else begin
            if (valid_in) begin
                a_reg <= a;
                b_reg <= b;
            end
            
            p1 <= a_reg * b_reg;
            p2 <= p1 + 1;
            p3 <= p2 + 1;
            result <= p3;
            
            valid_out <= valid_in;
        end
    end

endmodule