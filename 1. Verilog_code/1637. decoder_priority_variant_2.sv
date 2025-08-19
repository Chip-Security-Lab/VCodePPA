//SystemVerilog
module decoder_priority #(WIDTH=4) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);

localparam IDLE = 2'b00;
localparam CHECK = 2'b01;
localparam DONE = 2'b10;

// Pipeline stage 1 registers
reg [1:0] state_stage1, next_state_stage1;
reg [$clog2(WIDTH)-1:0] count_stage1, next_count_stage1;
reg [WIDTH-1:0] req_stage1;

// Pipeline stage 2 registers
reg [1:0] state_stage2;
reg [$clog2(WIDTH)-1:0] count_stage2;
reg [$clog2(WIDTH)-1:0] temp_grant_stage2, next_temp_grant_stage2;
reg [WIDTH-1:0] req_stage2;

// Pipeline stage 3 registers
reg [1:0] state_stage3;
reg [$clog2(WIDTH)-1:0] grant_stage3;

// Stage 1: Input and state transition
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1 <= IDLE;
        count_stage1 <= 0;
        req_stage1 <= 0;
    end else begin
        state_stage1 <= next_state_stage1;
        count_stage1 <= next_count_stage1;
        req_stage1 <= req;
    end
end

// Stage 1 next state logic
always @* begin
    next_state_stage1 = state_stage1;
    next_count_stage1 = count_stage1;
    
    case (state_stage1)
        IDLE: begin
            next_state_stage1 = CHECK;
            next_count_stage1 = 0;
        end
        
        CHECK: begin
            if (count_stage1 < WIDTH) begin
                next_count_stage1 = count_stage1 + 1;
            end else begin
                next_state_stage1 = DONE;
            end
        end
        
        DONE: begin
            next_state_stage1 = IDLE;
        end
    endcase
end

// Stage 2: Priority check
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2 <= IDLE;
        count_stage2 <= 0;
        temp_grant_stage2 <= 0;
        req_stage2 <= 0;
    end else begin
        state_stage2 <= state_stage1;
        count_stage2 <= count_stage1;
        temp_grant_stage2 <= next_temp_grant_stage2;
        req_stage2 <= req_stage1;
    end
end

// Stage 2 grant calculation
always @* begin
    next_temp_grant_stage2 = temp_grant_stage2;
    if (state_stage1 == CHECK && count_stage1 < WIDTH) begin
        if (req_stage1[count_stage1]) begin
            next_temp_grant_stage2 = count_stage1;
        end
    end
end

// Stage 3: Output generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage3 <= IDLE;
        grant_stage3 <= 0;
    end else begin
        state_stage3 <= state_stage2;
        if (state_stage2 == DONE) begin
            grant_stage3 <= temp_grant_stage2;
        end
    end
end

// Final output assignment
assign grant = grant_stage3;

endmodule