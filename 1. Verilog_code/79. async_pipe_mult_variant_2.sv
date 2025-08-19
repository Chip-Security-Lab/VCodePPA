//SystemVerilog
module async_pipe_mult (
    input [7:0] in1, in2,
    output [15:0] out,
    input req,
    output reg ack
);

    // Internal signals
    reg [7:0] in1_reg, in2_reg;
    reg [15:0] out_reg;
    reg [1:0] state;
    reg [1:0] state_buf1, state_buf2;
    
    // State definitions
    parameter IDLE = 2'b00;
    parameter COMPUTING = 2'b01;
    parameter COMPLETED = 2'b10;

    // State transition logic
    always @(posedge req or posedge ack) begin
        if (ack) begin
            state <= IDLE;
        end else if (req) begin
            case (state)
                IDLE: state <= COMPUTING;
                COMPUTING: state <= COMPLETED;
                default: state <= IDLE;
            endcase
        end
    end

    // Buffer state transitions
    always @(posedge req or posedge ack) begin
        if (ack) begin
            state_buf1 <= IDLE;
            state_buf2 <= IDLE;
        end else if (req) begin
            case (state)
                IDLE: begin
                    state_buf1 <= COMPUTING;
                    state_buf2 <= COMPUTING;
                end
                COMPUTING: begin
                    state_buf1 <= COMPLETED;
                    state_buf2 <= COMPLETED;
                end
                default: begin
                    state_buf1 <= IDLE;
                    state_buf2 <= IDLE;
                end
            endcase
        end
    end

    // Input register logic
    always @(posedge req) begin
        if (state == IDLE) begin
            in1_reg <= in1;
            in2_reg <= in2;
        end
    end

    // Computation logic
    always @(posedge req) begin
        if (state == COMPUTING) begin
            out_reg <= in1_reg * in2_reg;
        end
    end

    // Acknowledge logic
    always @(posedge req or posedge ack) begin
        if (ack) begin
            ack <= 1'b0;
        end else if (req && state == COMPLETED) begin
            ack <= 1'b1;
        end
    end

    // Output assignment
    assign out = out_reg;

    // Initial state
    initial begin
        state = IDLE;
        state_buf1 = IDLE;
        state_buf2 = IDLE;
        ack = 1'b0;
        out_reg = 16'h0000;
    end

endmodule