//SystemVerilog
// Counter submodule
module prog_clock_counter(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output reg [15:0] o_count,
    output reg o_count_done
);
    reg [15:0] count;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count <= 16'd0;
            o_count_done <= 1'b0;
        end else if (i_enable) begin
            if (count >= i_divisor - 1) begin
                count <= 16'd0;
                o_count_done <= 1'b1;
            end else begin
                count <= count + 16'd1;
                o_count_done <= 1'b0;
            end
        end else begin
            count <= 16'd0;
            o_count_done <= 1'b0;
        end
    end
    
    assign o_count = count;
endmodule

// State machine submodule
module prog_clock_fsm(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input i_count_done,
    output reg [1:0] o_state
);
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam COUNT = 2'b01;
    localparam TOGGLE = 2'b10;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: state <= (i_enable) ? COUNT : IDLE;
                COUNT: state <= (i_count_done) ? TOGGLE : COUNT;
                TOGGLE: state <= COUNT;
                default: state <= IDLE;
            endcase
        end
    end
    
    assign o_state = state;
endmodule

// Clock output submodule
module prog_clock_output(
    input i_clk,
    input i_rst_n,
    input [1:0] i_state,
    output reg o_clk
);
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_clk <= 1'b0;
        end else if (i_state == 2'b10) begin
            o_clk <= ~o_clk;
        end
    end
endmodule

// Top module
module prog_clock_gen(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output o_clk
);
    wire [15:0] count;
    wire count_done;
    wire [1:0] state;
    
    prog_clock_counter counter_inst(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),
        .i_divisor(i_divisor),
        .o_count(count),
        .o_count_done(count_done)
    );
    
    prog_clock_fsm fsm_inst(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),
        .i_count_done(count_done),
        .o_state(state)
    );
    
    prog_clock_output output_inst(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_state(state),
        .o_clk(o_clk)
    );
endmodule