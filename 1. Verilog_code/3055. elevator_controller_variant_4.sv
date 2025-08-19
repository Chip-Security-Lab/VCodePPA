//SystemVerilog
module elevator_controller(
    input wire clk, reset,
    input wire [3:0] floor_request,
    input wire up_down,
    output reg [3:0] current_floor,
    output reg moving, door_open
);
    localparam IDLE=2'b00, MOVING=2'b01, DOOR_OPENING=2'b10, DOOR_CLOSING=2'b11;
    reg [1:0] state, next;
    reg [3:0] target_floor;
    reg [3:0] timer;

    // Buffer registers for high fanout signals
    reg [3:0] floor_request_buf;
    reg [3:0] current_floor_buf;
    reg [1:0] state_buf;
    reg [1:0] next_buf;
    reg [3:0] target_floor_buf;

    // Karatsuba multiplier signals
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z1, z2;
    wire [3:0] karatsuba_result;

    // Input buffering
    always @(posedge clk) begin
        if (reset) begin
            floor_request_buf <= 4'd0;
        end else begin
            floor_request_buf <= floor_request;
        end
    end

    // State and control signal buffering
    always @(posedge clk) begin
        if (reset) begin
            state_buf <= IDLE;
            next_buf <= IDLE;
            target_floor_buf <= 4'd0;
            current_floor_buf <= 4'd0;
        end else begin
            state_buf <= state;
            next_buf <= next;
            target_floor_buf <= target_floor;
            current_floor_buf <= current_floor;
        end
    end

    // Split inputs for Karatsuba
    assign a_high = current_floor_buf[3:2];
    assign a_low = current_floor_buf[1:0];
    assign b_high = target_floor_buf[3:2];
    assign b_low = target_floor_buf[1:0];

    // Karatsuba multiplier implementation
    karatsuba_multiplier mult_inst (
        .a_high(a_high),
        .a_low(a_low),
        .b_high(b_high),
        .b_low(b_low),
        .z0(z0),
        .z1(z1),
        .z2(z2)
    );

    assign karatsuba_result = (z2 << 4) + (z1 << 2) + z0;

    // State register and timer logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            timer <= 4'd0;
        end else begin
            state <= next_buf;
            timer <= (state_buf != next_buf) ? 4'd0 : timer + 4'd1;
        end
    end

    // Current floor update logic
    always @(posedge clk) begin
        if (reset) begin
            current_floor <= 4'd0;
        end else if (state_buf == MOVING) begin
            current_floor <= (current_floor_buf < target_floor_buf) ? 
                            current_floor_buf + 1 : current_floor_buf - 1;
        end
    end

    // Output signal generation
    always @(*) begin
        moving = (state_buf == MOVING);
        door_open = (state_buf == DOOR_OPENING);
    end

    // Target floor selection
    always @(*) begin
        if (state_buf == IDLE && floor_request_buf != 0) begin
            target_floor = floor_request_buf;
        end
    end

    // Next state logic
    always @(*) begin
        next = state_buf;
        case (state_buf)
            IDLE: if (floor_request_buf != 0) begin
                next = (current_floor_buf != target_floor_buf) ? MOVING : DOOR_OPENING;
            end
            MOVING: if (current_floor_buf == target_floor_buf) next = DOOR_OPENING;
            DOOR_OPENING: if (timer >= 4'd10) next = DOOR_CLOSING;
            DOOR_CLOSING: if (timer >= 4'd5) next = IDLE;
        endcase
    end
endmodule

module karatsuba_multiplier(
    input wire [1:0] a_high,
    input wire [1:0] a_low,
    input wire [1:0] b_high,
    input wire [1:0] b_low,
    output wire [3:0] z0,
    output wire [3:0] z1,
    output wire [3:0] z2
);
    wire [1:0] a_sum, b_sum;
    wire [3:0] p0, p1, p2;

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    assign p0 = a_low * b_low;
    assign p1 = a_high * b_high;
    assign p2 = a_sum * b_sum;

    assign z0 = p0;
    assign z1 = p2 - p1 - p0;
    assign z2 = p1;
endmodule