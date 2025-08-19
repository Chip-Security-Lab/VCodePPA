//SystemVerilog
module micro_control_unit(
    input wire clk,
    input wire rst,
    input wire [7:0] instruction,
    input wire zero_flag,
    output wire req,
    output wire ack,
    output wire pc_inc,
    output wire acc_write,
    output wire mem_read,
    output wire mem_write,
    output wire [1:0] alu_op
);

    parameter [1:0] FETCH = 2'b00, DECODE = 2'b01, 
                    EXECUTE = 2'b10, WRITEBACK = 2'b11;
    
    wire [1:0] current_state;
    wire [1:0] next_state;
    wire [3:0] control_signals;
    
    state_register state_reg (
        .clk(clk),
        .rst(rst),
        .next_state(next_state),
        .current_state(current_state)
    );
    
    control_logic ctrl (
        .current_state(current_state),
        .instruction(instruction),
        .zero_flag(zero_flag),
        .next_state(next_state),
        .control_signals(control_signals)
    );
    
    signal_decoder decoder (
        .control_signals(control_signals),
        .req(req),
        .ack(ack),
        .pc_inc(pc_inc),
        .acc_write(acc_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_op(alu_op)
    );

endmodule

module state_register(
    input wire clk,
    input wire rst,
    input wire [1:0] next_state,
    output reg [1:0] current_state
);
    parameter [1:0] FETCH = 2'b00;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= FETCH;
        else
            current_state <= next_state;
    end
endmodule

module control_logic(
    input wire [1:0] current_state,
    input wire [7:0] instruction,
    input wire zero_flag,
    output reg [1:0] next_state,
    output reg [3:0] control_signals
);
    parameter [1:0] FETCH = 2'b00, DECODE = 2'b01, 
                    EXECUTE = 2'b10, WRITEBACK = 2'b11;
    
    always @(*) begin
        next_state = current_state;
        control_signals = 4'b0000;
        
        if (current_state == FETCH) begin
            control_signals[2] = 1'b1; // Request signal
            next_state = DECODE;
        end
        else if (current_state == DECODE) begin
            next_state = EXECUTE;
        end
        else if (current_state == EXECUTE) begin
            if (instruction[7:6] == 2'b00) begin
                control_signals[1:0] = 2'b00;
                next_state = WRITEBACK;
            end
            else if (instruction[7:6] == 2'b01) begin
                control_signals[1:0] = 2'b01;
                next_state = WRITEBACK;
            end
            else if (instruction[7:6] == 2'b10) begin
                control_signals[3] = 1'b1; // Acknowledge signal
                control_signals[2] = 1'b1; // Request signal
                next_state = FETCH;
            end
            else if (instruction[7:6] == 2'b11) begin
                control_signals[2] = ~zero_flag; // Request signal
                next_state = FETCH;
            end
        end
        else if (current_state == WRITEBACK) begin
            control_signals[2] = 1'b1; // Request signal
            control_signals[3] = 1'b1; // Acknowledge signal
            next_state = FETCH;
        end
    end
endmodule

module signal_decoder(
    input wire [3:0] control_signals,
    output reg req,
    output reg ack,
    output reg pc_inc,
    output reg acc_write,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] alu_op
);
    always @(*) begin
        req = control_signals[2];
        ack = control_signals[3];
        pc_inc = control_signals[2];
        acc_write = control_signals[3];
        mem_read = control_signals[2];
        mem_write = control_signals[3];
        alu_op = control_signals[1:0];
    end
endmodule