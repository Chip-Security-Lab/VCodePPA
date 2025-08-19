//SystemVerilog
module PartialProduct(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] result,
    output reg result_valid
);

    // Control signals
    wire calc_start;
    wire calc_done;
    wire [7:0] calc_result;
    
    // Control FSM
    ControlFSM u_control_fsm(
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .ready(ready),
        .calc_start(calc_start),
        .calc_done(calc_done)
    );
    
    // Calculation unit
    CalcUnit u_calc_unit(
        .clk(clk),
        .rst_n(rst_n),
        .calc_start(calc_start),
        .a(a),
        .b(b),
        .calc_done(calc_done),
        .result(calc_result)
    );
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'b0;
            result_valid <= 1'b0;
        end else if (calc_done) begin
            result <= calc_result;
            result_valid <= 1'b1;
        end else begin
            result_valid <= 1'b0;
        end
    end

endmodule

module ControlFSM(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    output reg calc_start,
    input calc_done
);

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            calc_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        state <= CALC;
                        ready <= 1'b0;
                        calc_start <= 1'b1;
                    end
                end
                
                CALC: begin
                    calc_start <= 1'b0;
                    if (calc_done) begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    ready <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

module CalcUnit(
    input clk,
    input rst_n,
    input calc_start,
    input [3:0] a,
    input [3:0] b,
    output reg calc_done,
    output reg [7:0] result
);

    reg [7:0] pp0, pp1, pp2, pp3;
    reg [7:0] result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calc_done <= 1'b0;
            result <= 8'b0;
            pp0 <= 8'b0;
            pp1 <= 8'b0;
            pp2 <= 8'b0;
            pp3 <= 8'b0;
        end else if (calc_start) begin
            pp0 <= b[0] ? {4'b0, a} : 0;
            pp1 <= b[1] ? {3'b0, a, 1'b0} : 0;
            pp2 <= b[2] ? {2'b0, a, 2'b0} : 0;
            pp3 <= b[3] ? {1'b0, a, 3'b0} : 0;
            result_reg <= pp0 + pp1 + pp2 + pp3;
            calc_done <= 1'b1;
        end else begin
            calc_done <= 1'b0;
        end
    end

endmodule