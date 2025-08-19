//SystemVerilog
module atomic_regfile #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input start,
    input [AW-1:0] addr,
    input [DW-1:0] modify_mask,
    input [DW-1:0] modify_val,
    output [DW-1:0] original_val,
    output busy
);

    reg [DW-1:0] mem [0:(1<<AW)-1];
    localparam IDLE = 2'b00, READ = 2'b01, DONE = 2'b10;
    reg [1:0] state;
    reg [DW-1:0] temp;
    
    assign busy = |state;
    assign original_val = temp;

    // State transition logic
    always @(posedge clk) begin
        case(state)
            IDLE: state <= (start) ? READ : IDLE;
            READ: state <= DONE;
            DONE: state <= IDLE;
            default: state <= IDLE;
        endcase
    end

    // Memory read operation
    always @(posedge clk) begin
        if (state == IDLE && start) begin
            temp <= mem[addr];
        end
    end

    // Memory write operation
    always @(posedge clk) begin
        if (state == READ) begin
            mem[addr] <= (temp & ~modify_mask) | (modify_val & modify_mask);
        end
    end

endmodule