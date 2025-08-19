//SystemVerilog
module ArbiterBridge #(
    parameter MASTERS = 4
)(
    input clk,
    input rst_n,
    input [MASTERS-1:0] req,
    output [MASTERS-1:0] grant
);

    // Pipeline stage 1: Request and Priority
    wire [MASTERS-1:0] req_sync;
    wire [1:0] priority_ptr;
    wire [1:0] next_priority;
    
    // Pipeline stage 2: Grant Generation
    wire [MASTERS-1:0] grant_candidate;
    wire grant_valid;
    
    // Pipeline stage 3: Grant Output
    reg [MASTERS-1:0] grant_reg;

    // Stage 1: Request Synchronization and Priority Management
    RequestSync #(
        .MASTERS(MASTERS)
    ) req_sync_inst (
        .clk(clk),
        .rst_n(rst_n),
        .req_in(req),
        .req_out(req_sync)
    );

    PriorityManager #(
        .MASTERS(MASTERS)
    ) priority_mgr (
        .clk(clk),
        .rst_n(rst_n),
        .next_priority(next_priority),
        .current_priority(priority_ptr)
    );

    // Stage 2: Grant Generation Logic
    GrantGenerator #(
        .MASTERS(MASTERS)
    ) grant_gen (
        .req(req_sync),
        .priority_ptr(priority_ptr),
        .grant_candidate(grant_candidate),
        .grant_valid(grant_valid),
        .next_priority(next_priority)
    );

    // Stage 3: Grant Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_reg <= 0;
        end else if (grant_valid) begin
            grant_reg <= grant_candidate;
        end else begin
            grant_reg <= 0;
        end
    end

    assign grant = grant_reg;
endmodule

module RequestSync #(
    parameter MASTERS = 4
)(
    input clk,
    input rst_n,
    input [MASTERS-1:0] req_in,
    output reg [MASTERS-1:0] req_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_out <= 0;
        end else begin
            req_out <= req_in;
        end
    end
endmodule

module PriorityManager #(
    parameter MASTERS = 4
)(
    input clk,
    input rst_n,
    input [1:0] next_priority,
    output reg [1:0] current_priority
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_priority <= 0;
        end else begin
            current_priority <= next_priority;
        end
    end
endmodule

module GrantGenerator #(
    parameter MASTERS = 4
)(
    input [MASTERS-1:0] req,
    input [1:0] priority_ptr,
    output reg [MASTERS-1:0] grant_candidate,
    output reg grant_valid,
    output reg [1:0] next_priority
);
    integer i;
    
    always @(*) begin
        grant_valid = 0;
        grant_candidate = 0;
        next_priority = priority_ptr;
        
        for (i = 0; i < MASTERS; i = i + 1) begin
            if (req[(priority_ptr+i)%MASTERS] && !grant_valid) begin
                grant_candidate = 1 << ((priority_ptr+i)%MASTERS);
                next_priority = (priority_ptr+i+1)%MASTERS;
                grant_valid = 1;
            end
        end
    end
endmodule