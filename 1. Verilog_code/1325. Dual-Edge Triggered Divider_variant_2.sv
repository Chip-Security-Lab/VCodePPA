//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module dual_edge_divider (
    input  wire clkin, 
    input  wire rst,
    output wire clkout
);
    // Internal wires for connecting submodules
    wire pos_toggle_out, neg_toggle_out;
    wire valid_out;
    
    // Instantiate positive edge pipeline processing module
    pos_edge_pipeline pos_pipeline (
        .clkin        (clkin),
        .rst          (rst),
        .pos_toggle   (pos_toggle_out),
        .valid        (valid_out)
    );
    
    // Instantiate negative edge pipeline processing module
    neg_edge_pipeline neg_pipeline (
        .clkin        (clkin),
        .rst          (rst),
        .neg_toggle   (neg_toggle_out)
    );
    
    // Instantiate output generation module
    output_generator output_gen (
        .pos_toggle   (pos_toggle_out),
        .neg_toggle   (neg_toggle_out),
        .valid        (valid_out),
        .clkout       (clkout)
    );
    
endmodule

module pos_edge_pipeline (
    input  wire clkin,
    input  wire rst,
    output reg  pos_toggle,
    output reg  valid
);
    // Pipeline stage 1 - Counter registers
    reg [1:0] count_stage1;
    reg toggle_stage1;
    
    // Pipeline stage 2 - Intermediate registers
    reg [1:0] count_stage2;
    reg toggle_stage2;
    
    // Valid signals for pipeline control
    reg valid_stage1, valid_stage2;
    
    // Assign outputs to the final stage values
    assign pos_toggle = toggle_stage2;
    assign valid = valid_stage2;
    
    // Positive edge pipeline
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            // Initialize pipeline stage 1
            count_stage1 <= 2'b00;
            toggle_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            // Initialize pipeline stage 2
            count_stage2 <= 2'b00;
            toggle_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end 
        else begin
            // Stage 1: Counter logic
            valid_stage1 <= 1'b1;
            if (count_stage1 == 2'b11) begin
                count_stage1 <= 2'b00;
                toggle_stage1 <= ~toggle_stage1;
            end 
            else begin
                count_stage1 <= count_stage1 + 1'b1;
            end
            
            // Stage 2: Final processing stage
            valid_stage2 <= valid_stage1;
            count_stage2 <= count_stage1;
            toggle_stage2 <= toggle_stage1;
        end
    end
endmodule

module neg_edge_pipeline (
    input  wire clkin,
    input  wire rst,
    output reg  neg_toggle
);
    // Pipeline stage 1 - Counter registers
    reg [1:0] count_stage1;
    reg toggle_stage1;
    
    // Pipeline stage 2 - Intermediate registers
    reg [1:0] count_stage2;
    reg toggle_stage2;
    
    // Assign output to the final stage value
    assign neg_toggle = toggle_stage2;
    
    // Negative edge pipeline
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            // Initialize negative edge pipeline
            count_stage1 <= 2'b00;
            toggle_stage1 <= 1'b0;
            count_stage2 <= 2'b00;
            toggle_stage2 <= 1'b0;
        end 
        else begin
            // Stage 1: Counter logic
            if (count_stage1 == 2'b11) begin
                count_stage1 <= 2'b00;
                toggle_stage1 <= ~toggle_stage1;
            end 
            else begin
                count_stage1 <= count_stage1 + 1'b1;
            end
            
            // Stage 2: Final processing stage
            count_stage2 <= count_stage1;
            toggle_stage2 <= toggle_stage1;
        end
    end
endmodule

module output_generator (
    input  wire pos_toggle,
    input  wire neg_toggle,
    input  wire valid,
    output reg  clkout
);
    // Output generation logic - Combinational with registered inputs
    always @(pos_toggle or neg_toggle) begin
        if (valid) begin
            clkout = pos_toggle ^ neg_toggle;
        end
    end
endmodule