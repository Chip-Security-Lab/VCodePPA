//SystemVerilog
// SystemVerilog IEEE 1364-2005
// Top-level module
module int_ctrl_dynamic #(
    parameter N_SRC = 8
)(
    input wire clk,
    input wire rst,
    input wire [N_SRC-1:0] req,
    input wire [N_SRC*8-1:0] prio_map,
    output wire [2:0] curr_pri
);
    // Internal signals for connecting submodules
    wire [N_SRC-1:0] req_stage1;
    wire [N_SRC*8-1:0] prio_map_stage1;
    wire [2:0] prio_stage1_high;
    wire [2:0] prio_stage1_low;
    wire prio_stage1_high_valid;
    wire prio_stage1_low_valid;
    wire [2:0] temp_pri_stage2;

    // Stage 1: Priority calculation
    priority_calc_stage1 #(
        .N_SRC(N_SRC)
    ) stage1_inst (
        .clk(clk),
        .rst(rst),
        .req_in(req),
        .prio_map_in(prio_map),
        .req_out(req_stage1),
        .prio_map_out(prio_map_stage1),
        .high_prio(prio_stage1_high),
        .low_prio(prio_stage1_low),
        .high_prio_valid(prio_stage1_high_valid),
        .low_prio_valid(prio_stage1_low_valid)
    );

    // Stage 2: Priority selection and output
    priority_select_stage2 #(
        .N_SRC(N_SRC)
    ) stage2_inst (
        .clk(clk),
        .rst(rst),
        .req_in(req_stage1),
        .prio_map_in(prio_map_stage1),
        .high_prio(prio_stage1_high),
        .low_prio(prio_stage1_low),
        .high_prio_valid(prio_stage1_high_valid),
        .low_prio_valid(prio_stage1_low_valid),
        .curr_pri(curr_pri)
    );

endmodule

// First stage module: Calculate priorities for high and low groups
module priority_calc_stage1 #(
    parameter N_SRC = 8
)(
    input wire clk,
    input wire rst,
    input wire [N_SRC-1:0] req_in,
    input wire [N_SRC*8-1:0] prio_map_in,
    output reg [N_SRC-1:0] req_out,
    output reg [N_SRC*8-1:0] prio_map_out,
    output reg [2:0] high_prio,
    output reg [2:0] low_prio,
    output reg high_prio_valid,
    output reg low_prio_valid
);
    integer i, j;
    
    always @(posedge clk) begin
        if (rst) begin
            req_out <= {N_SRC{1'b0}};
            prio_map_out <= {(N_SRC*8){1'b0}};
            high_prio <= 3'b0;
            low_prio <= 3'b0;
            high_prio_valid <= 1'b0;
            low_prio_valid <= 1'b0;
        end
        else begin
            // Forward inputs to next stage
            req_out <= req_in;
            prio_map_out <= prio_map_in;
            
            // Calculate high priorities (7,6,5,4)
            high_prio_valid <= 1'b0;
            for (i = 7; i >= 4; i = i - 1) begin
                for (j = 0; j < N_SRC; j = j + 1) begin
                    if (req_in[j] & prio_map_in[i*N_SRC+j]) begin
                        high_prio <= i[2:0];
                        high_prio_valid <= 1'b1;
                    end
                end
            end
            
            // Calculate low priorities (3,2,1,0)
            low_prio_valid <= 1'b0;
            for (i = 3; i >= 0; i = i - 1) begin
                for (j = 0; j < N_SRC; j = j + 1) begin
                    if (req_in[j] & prio_map_in[i*N_SRC+j]) begin
                        low_prio <= i[2:0];
                        low_prio_valid <= 1'b1;
                    end
                end
            end
        end
    end
endmodule

// Second stage module: Select and output final priority
module priority_select_stage2 #(
    parameter N_SRC = 8
)(
    input wire clk,
    input wire rst,
    input wire [N_SRC-1:0] req_in,
    input wire [N_SRC*8-1:0] prio_map_in,
    input wire [2:0] high_prio,
    input wire [2:0] low_prio,
    input wire high_prio_valid,
    input wire low_prio_valid,
    output reg [2:0] curr_pri
);
    reg [2:0] temp_pri;
    
    always @(posedge clk) begin
        if (rst) begin
            temp_pri <= 3'b0;
            curr_pri <= 3'b0;
        end
        else begin
            // Select highest priority between high and low groups
            if (high_prio_valid)
                temp_pri <= high_prio;
            else if (low_prio_valid)
                temp_pri <= low_prio;
            else
                temp_pri <= 3'b0;
                
            // Final output stage
            curr_pri <= temp_pri;
        end
    end
endmodule