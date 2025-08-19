//SystemVerilog
module bin_reflected_gray_gen #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] gray_code
);

    reg [WIDTH-1:0] counter;

    localparam IDLE_STATE   = 2'b00;
    localparam ENABLE_STATE = 2'b01;

    reg [1:0] current_state;

    // Synchronous state machine to avoid race conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE_STATE;
        else if (enable)
            current_state <= ENABLE_STATE;
        else
            current_state <= IDLE_STATE;
    end

    // Bucket shifter implementation for (counter + 1'b1) >> 1
    function [WIDTH-1:0] barrel_shifter_right;
        input [WIDTH-1:0] data_in;
        input [$clog2(WIDTH):0] shift_amt;
        integer i, j;
        reg [WIDTH-1:0] stage [0:$clog2(WIDTH)];
    begin
        stage[0] = data_in;
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin
            for (j = 0; j < WIDTH; j = j + 1) begin
                if (j >= (1 << i))
                    stage[i+1][j] = shift_amt[i] ? stage[i][j-(1<<i)] : stage[i][j];
                else
                    stage[i+1][j] = shift_amt[i] ? 1'b0 : stage[i][j];
            end
        end
        barrel_shifter_right = stage[$clog2(WIDTH)];
    end
    endfunction

    reg [WIDTH-1:0] counter_next;
    reg [WIDTH-1:0] gray_code_next;

    always @(*) begin
        counter_next   = counter;
        gray_code_next = gray_code;
        case (current_state)
            IDLE_STATE: begin
                counter_next   = {WIDTH{1'b0}};
                gray_code_next = {WIDTH{1'b0}};
            end
            ENABLE_STATE: begin
                counter_next   = counter + 1'b1;
                gray_code_next = (counter + 1'b1) ^ barrel_shifter_right((counter + 1'b1), 1);
            end
            default: begin
                counter_next   = counter;
                gray_code_next = gray_code;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= {WIDTH{1'b0}};
            gray_code <= {WIDTH{1'b0}};
        end else begin
            counter   <= counter_next;
            gray_code <= gray_code_next;
        end
    end

endmodule