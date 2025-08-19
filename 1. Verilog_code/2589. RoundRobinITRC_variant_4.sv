//SystemVerilog
module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);

    wire [2:0] next_position;
    wire [2:0] next_id;
    
    // 实例化轮询逻辑子模块
    RoundRobinLogic #(.WIDTH(WIDTH)) rr_logic (
        .current_position(current_position),
        .interrupts(interrupts),
        .next_position(next_position),
        .next_id(next_id)
    );
    
    // 实例化控制逻辑子模块
    ControlLogic control (
        .clock(clock),
        .reset(reset),
        .interrupts(interrupts),
        .next_position(next_position),
        .next_id(next_id),
        .service_req(service_req),
        .service_id(service_id),
        .current_position(current_position)
    );

endmodule

module RoundRobinLogic #(parameter WIDTH=8) (
    input wire [2:0] current_position,
    input wire [WIDTH-1:0] interrupts,
    output reg [2:0] next_position,
    output reg [2:0] next_id
);

    always @(*) begin
        case (current_position)
            0: begin
                if (interrupts[0]) begin
                    next_id = 0;
                    next_position = 1;
                end
                else if (interrupts[1]) begin
                    next_id = 1;
                    next_position = 2;
                end
                else if (interrupts[2]) begin
                    next_id = 2;
                    next_position = 3;
                end
                else if (interrupts[3]) begin
                    next_id = 3;
                    next_position = 4;
                end
                else if (interrupts[4]) begin
                    next_id = 4;
                    next_position = 5;
                end
                else if (interrupts[5]) begin
                    next_id = 5;
                    next_position = 6;
                end
                else if (interrupts[6]) begin
                    next_id = 6;
                    next_position = 7;
                end
                else if (interrupts[7]) begin
                    next_id = 7;
                    next_position = 0;
                end
            end
            1: begin
                if (interrupts[1]) begin
                    next_id = 1;
                    next_position = 2;
                end
                else if (interrupts[2]) begin
                    next_id = 2;
                    next_position = 3;
                end
                else if (interrupts[3]) begin
                    next_id = 3;
                    next_position = 4;
                end
                else if (interrupts[4]) begin
                    next_id = 4;
                    next_position = 5;
                end
                else if (interrupts[5]) begin
                    next_id = 5;
                    next_position = 6;
                end
                else if (interrupts[6]) begin
                    next_id = 6;
                    next_position = 7;
                end
                else if (interrupts[7]) begin
                    next_id = 7;
                    next_position = 0;
                end
                else if (interrupts[0]) begin
                    next_id = 0;
                    next_position = 1;
                end
            end
            default: begin
                next_position = 0;
                next_id = 0;
            end
        endcase
    end
endmodule

module ControlLogic (
    input wire clock,
    input wire reset,
    input wire [7:0] interrupts,
    input wire [2:0] next_position,
    input wire [2:0] next_id,
    output reg service_req,
    output reg [2:0] service_id,
    output reg [2:0] current_position
);

    always @(posedge clock) begin
        if (reset) begin
            current_position <= 0;
            service_req <= 0;
            service_id <= 0;
        end else begin
            service_req <= |interrupts;
            if (|interrupts) begin
                current_position <= next_position;
                service_id <= next_id;
            end
        end
    end
endmodule