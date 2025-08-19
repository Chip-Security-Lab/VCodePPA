//SystemVerilog
module karatsuba_multiplier_4bit_pipelined(
    input wire clk,
    input wire reset,
    input wire [3:0] a,
    input wire [3:0] b,
    output reg [7:0] product
);
    // Stage 1 registers
    reg [1:0] a_high_stage1, a_low_stage1;
    reg [1:0] b_high_stage1, b_low_stage1;
    
    // Stage 2 registers
    reg [3:0] z0_stage2, z2_stage2;
    reg [3:0] a_sum_stage2, b_sum_stage2;
    
    // Stage 3 registers
    reg [3:0] z1_stage3;
    
    // Stage 4 registers
    reg [3:0] z1_sub_stage4;
    reg [3:0] z0_stage4, z2_stage4;
    
    // Stage 1: Input splitting
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_high_stage1 <= 2'b0;
            a_low_stage1 <= 2'b0;
            b_high_stage1 <= 2'b0;
            b_low_stage1 <= 2'b0;
        end else begin
            a_high_stage1 <= a[3:2];
            a_low_stage1 <= a[1:0];
            b_high_stage1 <= b[3:2];
            b_low_stage1 <= b[1:0];
        end
    end
    
    // Stage 2: First level multiplications and additions
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            z0_stage2 <= 4'b0;
            z2_stage2 <= 4'b0;
            a_sum_stage2 <= 4'b0;
            b_sum_stage2 <= 4'b0;
        end else begin
            z0_stage2 <= a_low_stage1 * b_low_stage1;
            z2_stage2 <= a_high_stage1 * b_high_stage1;
            a_sum_stage2 <= a_high_stage1 + a_low_stage1;
            b_sum_stage2 <= b_high_stage1 + b_low_stage1;
        end
    end
    
    // Stage 3: Second level multiplication
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            z1_stage3 <= 4'b0;
        end else begin
            z1_stage3 <= a_sum_stage2 * b_sum_stage2;
        end
    end
    
    // Stage 4: Final subtraction and shift
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            z1_sub_stage4 <= 4'b0;
            z0_stage4 <= 4'b0;
            z2_stage4 <= 4'b0;
        end else begin
            z1_sub_stage4 <= z1_stage3 - z0_stage2 - z2_stage2;
            z0_stage4 <= z0_stage2;
            z2_stage4 <= z2_stage2;
        end
    end
    
    // Final output calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            product <= 8'b0;
        end else begin
            product <= (z2_stage4 << 4) + (z1_sub_stage4 << 2) + z0_stage4;
        end
    end
endmodule

module elevator_controller_pipelined(
    input wire clk,
    input wire reset,
    input wire [3:0] floor_request,
    input wire door_closed,
    input wire at_floor,
    output reg [1:0] motor_control,
    output reg door_open,
    output reg req,
    input wire ack
);
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;
    
    // Stage 1 registers
    reg [1:0] state_stage1, next_state_stage1;
    reg [1:0] current_floor_stage1, target_floor_stage1;
    reg [3:0] floor_request_stage1;
    reg door_closed_stage1, at_floor_stage1;
    
    // Stage 2 registers
    reg [1:0] state_stage2;
    reg [1:0] current_floor_stage2, target_floor_stage2;
    reg [3:0] multiplier_a_stage2, multiplier_b_stage2;
    
    // Stage 3 registers
    reg [1:0] state_stage3;
    reg [1:0] current_floor_stage3, target_floor_stage3;
    wire [7:0] floor_product;
    
    // Instantiate pipelined multiplier
    karatsuba_multiplier_4bit_pipelined mult_inst(
        .clk(clk),
        .reset(reset),
        .a(multiplier_a_stage2),
        .b(multiplier_b_stage2),
        .product(floor_product)
    );
    
    // Stage 1: Input sampling and state update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            current_floor_stage1 <= 2'b00;
            target_floor_stage1 <= 2'b00;
            floor_request_stage1 <= 4'b0;
            door_closed_stage1 <= 1'b0;
            at_floor_stage1 <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage1;
            floor_request_stage1 <= floor_request;
            door_closed_stage1 <= door_closed;
            at_floor_stage1 <= at_floor;
            if (at_floor_stage1 && (state_stage1 == MOVING_UP || state_stage1 == MOVING_DOWN)) begin
                current_floor_stage1 <= target_floor_stage1;
            end
        end
    end
    
    // Stage 2: State transition and multiplier input preparation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            current_floor_stage2 <= 2'b00;
            target_floor_stage2 <= 2'b00;
            multiplier_a_stage2 <= 4'b0;
            multiplier_b_stage2 <= 4'b0;
        end else begin
            state_stage2 <= state_stage1;
            current_floor_stage2 <= current_floor_stage1;
            target_floor_stage2 <= target_floor_stage1;
            multiplier_a_stage2 <= {2'b00, current_floor_stage1};
            multiplier_b_stage2 <= {2'b00, target_floor_stage1};
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            current_floor_stage3 <= 2'b00;
            target_floor_stage3 <= 2'b00;
            motor_control <= 2'b00;
            door_open <= 1'b0;
            req <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            current_floor_stage3 <= current_floor_stage2;
            target_floor_stage3 <= target_floor_stage2;
            
            case (state_stage2)
                IDLE: begin
                    if (|floor_request_stage1) begin
                        req <= 1'b1;
                        if (floor_request_stage1[3] || floor_request_stage1[2]) begin
                            next_state_stage1 <= MOVING_UP;
                            target_floor_stage1 <= floor_request_stage1[3] ? 2'b11 : 2'b10;
                        end else begin
                            next_state_stage1 <= MOVING_DOWN;
                            target_floor_stage1 <= floor_request_stage1[0] ? 2'b00 : 2'b01;
                        end
                    end
                    door_open <= 1'b1;
                end
                MOVING_UP: begin
                    motor_control <= 2'b01;
                    if (at_floor_stage1) begin
                        next_state_stage1 <= DOOR_OPENING;
                        req <= 1'b0;
                    end
                end
                MOVING_DOWN: begin
                    motor_control <= 2'b10;
                    if (at_floor_stage1) begin
                        next_state_stage1 <= DOOR_OPENING;
                        req <= 1'b0;
                    end
                end
                DOOR_OPENING: begin
                    door_open <= 1'b1;
                    if (door_closed_stage1) next_state_stage1 <= IDLE;
                end
            endcase
        end
    end
endmodule