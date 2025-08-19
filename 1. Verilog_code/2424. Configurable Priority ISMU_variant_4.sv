//SystemVerilog
// Top-level module
module config_priority_ismu #(
    parameter N_SRC = 8
)(
    input  wire                clock,
    input  wire                resetn,
    input  wire [N_SRC-1:0]    interrupt_in,
    input  wire [N_SRC-1:0]    interrupt_mask,
    input  wire [3*N_SRC-1:0]  priority_config,
    output wire [2:0]          highest_priority,
    output wire                interrupt_valid
);
    // Internal signals
    wire [2:0] curr_priority [N_SRC-1:0];
    wire [2:0] max_priority_comb;
    wire [2:0] highest_idx_comb;
    wire       valid_comb;
    
    // Priority extraction module (purely combinational)
    priority_extractor #(
        .N_SRC(N_SRC)
    ) u_priority_extractor (
        .priority_config(priority_config),
        .curr_priority(curr_priority)
    );
    
    // Priority comparison module (purely combinational)
    priority_comparator_comb #(
        .N_SRC(N_SRC)
    ) u_priority_comparator (
        .interrupt_in(interrupt_in),
        .interrupt_mask(interrupt_mask),
        .curr_priority(curr_priority),
        .max_priority(max_priority_comb),
        .highest_idx(highest_idx_comb),
        .valid(valid_comb)
    );
    
    // Output sequential register module (purely sequential)
    output_register_seq u_output_register (
        .clock(clock),
        .resetn(resetn),
        .max_priority_in(max_priority_comb),
        .highest_idx_in(highest_idx_comb),
        .valid_in(valid_comb),
        .highest_priority(highest_priority),
        .interrupt_valid(interrupt_valid)
    );
    
endmodule

// Priority extraction module (purely combinational)
module priority_extractor #(
    parameter N_SRC = 8
)(
    input  wire [3*N_SRC-1:0] priority_config,
    output wire [2:0]         curr_priority [N_SRC-1:0]
);
    genvar i;
    
    // Extract individual priorities from the priority_config vector
    generate
        for (i = 0; i < N_SRC; i = i + 1) begin : gen_priority
            assign curr_priority[i] = priority_config[i*3+:3];
        end
    endgenerate
    
endmodule

// Priority comparison module (purely combinational)
module priority_comparator_comb #(
    parameter N_SRC = 8
)(
    input  wire [N_SRC-1:0] interrupt_in,
    input  wire [N_SRC-1:0] interrupt_mask,
    input  wire [2:0]       curr_priority [N_SRC-1:0],
    output wire [2:0]       max_priority,
    output wire [2:0]       highest_idx,
    output wire             valid
);
    // Internal combinational signals
    reg [2:0] max_priority_reg;
    reg [2:0] highest_idx_reg;
    reg       valid_reg;
    integer i;
    
    // Combinational always block
    always @(*) begin
        max_priority_reg = 3'd0;
        highest_idx_reg = 3'd0;
        valid_reg = 1'b0;
        
        for (i = 0; i < N_SRC; i = i + 1) begin
            if (interrupt_in[i] && !interrupt_mask[i] && 
                curr_priority[i] > max_priority_reg) begin
                max_priority_reg = curr_priority[i];
                highest_idx_reg = i[2:0];
                valid_reg = 1'b1;
            end
        end
    end
    
    // Connect internal registers to outputs
    assign max_priority = max_priority_reg;
    assign highest_idx = highest_idx_reg;
    assign valid = valid_reg;
    
endmodule

// Output sequential register module (purely sequential)
module output_register_seq (
    input  wire       clock,
    input  wire       resetn,
    input  wire [2:0] max_priority_in,
    input  wire [2:0] highest_idx_in,
    input  wire       valid_in,
    output reg  [2:0] highest_priority,
    output reg        interrupt_valid
);
    
    // Sequential logic only
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            interrupt_valid <= 1'b0;
            highest_priority <= 3'd0;
        end else begin
            highest_priority <= highest_idx_in;
            interrupt_valid <= valid_in;
        end
    end
    
endmodule