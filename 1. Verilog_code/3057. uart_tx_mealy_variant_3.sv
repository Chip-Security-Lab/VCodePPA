//SystemVerilog
module uart_tx_mealy(
    input wire clk, rst_n,
    input wire tx_start,
    input wire [7:0] tx_data,
    output wire tx_busy, tx_out
);

    // Control signals
    wire [1:0] state;
    wire [1:0] next_state;
    wire [2:0] bit_index;
    wire [7:0] data_reg;
    wire data_load;
    wire bit_count_en;
    wire bit_count_rst;

    // Instantiate state machine
    uart_tx_fsm fsm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .bit_index(bit_index),
        .state(state),
        .next_state(next_state),
        .data_load(data_load),
        .bit_count_en(bit_count_en),
        .bit_count_rst(bit_count_rst)
    );

    // Instantiate data register
    uart_tx_data_reg data_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_load(data_load),
        .tx_data(tx_data),
        .data_reg(data_reg)
    );

    // Instantiate bit counter
    uart_tx_bit_counter bit_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bit_count_en(bit_count_en),
        .bit_count_rst(bit_count_rst),
        .bit_index(bit_index)
    );

    // Instantiate output logic
    uart_tx_output output_inst (
        .state(state),
        .data_reg(data_reg),
        .bit_index(bit_index),
        .tx_busy(tx_busy),
        .tx_out(tx_out)
    );

endmodule

module uart_tx_fsm(
    input wire clk, rst_n,
    input wire tx_start,
    input wire [2:0] bit_index,
    output reg [1:0] state,
    output reg [1:0] next_state,
    output reg data_load,
    output reg bit_count_en,
    output reg bit_count_rst
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end

    always @(*) begin
        data_load = 1'b0;
        bit_count_en = 1'b0;
        bit_count_rst = 1'b0;
        
        case (state)
            IDLE: begin
                next_state = tx_start ? START : IDLE;
                data_load = tx_start;
            end
            START: begin
                next_state = DATA;
                bit_count_rst = 1'b1;
            end
            DATA: begin
                next_state = (bit_index == 3'd7) ? STOP : DATA;
                bit_count_en = 1'b1;
            end
            STOP: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule

module uart_tx_data_reg(
    input wire clk, rst_n,
    input wire data_load,
    input wire [7:0] tx_data,
    output reg [7:0] data_reg
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            data_reg <= 8'd0;
        end else if (data_load) begin
            data_reg <= tx_data;
        end
endmodule

module uart_tx_bit_counter(
    input wire clk, rst_n,
    input wire bit_count_en,
    input wire bit_count_rst,
    output reg [2:0] bit_index
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            bit_index <= 3'd0;
        end else if (bit_count_rst) begin
            bit_index <= 3'd0;
        end else if (bit_count_en) begin
            bit_index <= (bit_index == 3'd7) ? 3'd0 : bit_index + 3'd1;
        end
endmodule

module uart_tx_output(
    input wire [1:0] state,
    input wire [7:0] data_reg,
    input wire [2:0] bit_index,
    output reg tx_busy,
    output reg tx_out
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;

    always @(*) begin
        tx_busy = (state != IDLE);
        
        case (state)
            IDLE: tx_out = 1'b1;
            START: tx_out = 1'b0;
            DATA: tx_out = data_reg[bit_index];
            STOP: tx_out = 1'b1;
        endcase
    end
endmodule