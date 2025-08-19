//SystemVerilog
module elevator_controller(
    input wire clk, reset,
    input wire [3:0] floor_request,
    input wire up_down, // 0:up, 1:down
    output reg [3:0] current_floor,
    output reg moving, door_open
);
    localparam IDLE=2'b00, MOVING=2'b01, DOOR_OPENING=2'b10, DOOR_CLOSING=2'b11;
    reg [1:0] state, next;
    reg [3:0] target_floor;
    reg [3:0] timer;
    
    // Kogge-Stone adder signals
    wire [3:0] sum;
    wire [3:0] a, b;
    wire cin;
    
    // Assign inputs to the adder
    assign a = current_floor;
    assign b = (current_floor < target_floor) ? 4'b0001 : 4'b1111; // +1 or -1
    assign cin = 1'b0;
    
    // Kogge-Stone adder implementation
    kogge_stone_adder_4bit kogge_stone_adder(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout()
    );
    
    always @(posedge clk)
        if (reset) begin
            state <= IDLE; current_floor <= 4'd0; timer <= 4'd0;
        end else begin
            state <= next;
            if (state == MOVING)
                current_floor <= sum;
            timer <= (state != next) ? 4'd0 : timer + 4'd1;
        end
    
    always @(*) begin
        moving = (state == MOVING);
        door_open = (state == DOOR_OPENING);
        next = state;
        
        case (state)
            IDLE: if (floor_request != 0) begin
                target_floor = floor_request;
                next = (current_floor != target_floor) ? MOVING : DOOR_OPENING;
            end
            MOVING: if (current_floor == target_floor) next = DOOR_OPENING;
            DOOR_OPENING: if (timer >= 4'd10) next = DOOR_CLOSING;
            DOOR_CLOSING: if (timer >= 4'd5) next = IDLE;
        endcase
    end
endmodule

module kogge_stone_adder_4bit(
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,
    output wire [3:0] sum,
    output wire cout
);
    wire [3:0] g, p;
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;
    wire [3:0] carry;
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    
    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    
    // Final carry calculation
    assign carry[0] = cin;
    assign carry[1] = g2[0] | (p2[0] & cin);
    assign carry[2] = g2[1] | (p2[1] & cin);
    assign carry[3] = g2[2] | (p2[2] & cin);
    assign cout = g2[3] | (p2[3] & cin);
    
    // Sum calculation
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
endmodule