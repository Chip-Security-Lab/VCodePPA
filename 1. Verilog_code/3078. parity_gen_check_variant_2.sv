//SystemVerilog
module parity_gen_check(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire parity_type, // 0:even, 1:odd
    input wire gen_check_n, // 0:check, 1:generate
    output reg parity_bit,
    output reg error
);

    localparam IDLE=2'b00, COMPUTE=2'b01, OUTPUT=2'b10, ERROR_STATE=2'b11;
    reg [1:0] state, next;
    reg [7:0] data_reg;
    reg computed_parity;
    wire parity_result;
    wire check_error;
    
    // Parity computation logic
    assign parity_result = ^data_reg ^ parity_type;
    assign check_error = computed_parity ^ parity_bit;

    // State register update
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next;
        end

    // Data register update
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            data_reg <= 8'd0;
        end else if (state == IDLE && data_valid) begin
            data_reg <= data_in;
        end

    // Parity computation register
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            computed_parity <= 1'b0;
        end else if (state == COMPUTE) begin
            computed_parity <= parity_result;
        end

    // Parity bit generation
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            parity_bit <= 1'b0;
        end else if (state == COMPUTE && gen_check_n) begin
            parity_bit <= parity_result;
        end

    // Error detection and state
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            error <= 1'b0;
        end else begin
            case (state)
                IDLE: error <= 1'b0;
                OUTPUT: if (!gen_check_n) error <= check_error;
                ERROR_STATE: error <= 1'b1;
                default: error <= error;
            endcase
        end

    // Next state logic
    always @(*)
        case (state)
            IDLE: next = data_valid ? COMPUTE : IDLE;
            COMPUTE: next = OUTPUT;
            OUTPUT: next = (!gen_check_n && check_error) ? ERROR_STATE : IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase

endmodule