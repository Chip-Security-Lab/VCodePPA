//SystemVerilog
// Top-level module
module wakeup_ismu 
#(
    parameter INT_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire sleep_mode,
    input wire [INT_WIDTH-1:0] int_src,
    input wire [INT_WIDTH-1:0] wakeup_mask,
    output wire wakeup,
    output wire [INT_WIDTH-1:0] pending_int
);

    // Internal connections
    wire [INT_WIDTH-1:0] wake_sources;
    reg [INT_WIDTH-1:0] int_src_reg;
    reg [INT_WIDTH-1:0] wakeup_mask_reg;
    
    // Register inputs to break long timing paths from input pins
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_reg <= {INT_WIDTH{1'b0}};
            wakeup_mask_reg <= {INT_WIDTH{1'b0}};
        end else begin
            int_src_reg <= int_src;
            wakeup_mask_reg <= wakeup_mask;
        end
    end

    // Instantiate interrupt source filter module
    interrupt_filter #(
        .INT_WIDTH(INT_WIDTH)
    ) int_filter_inst (
        .int_src(int_src_reg),
        .wakeup_mask(wakeup_mask_reg),
        .wake_sources(wake_sources)
    );

    // Instantiate wakeup controller module
    wakeup_controller #(
        .INT_WIDTH(INT_WIDTH)
    ) wakeup_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sleep_mode(sleep_mode),
        .int_src(int_src_reg),
        .wake_sources(wake_sources),
        .wakeup(wakeup),
        .pending_int(pending_int)
    );

endmodule

// Submodule for filtering interrupt sources
module interrupt_filter 
#(
    parameter INT_WIDTH = 8
)(
    input wire [INT_WIDTH-1:0] int_src,
    input wire [INT_WIDTH-1:0] wakeup_mask,
    output wire [INT_WIDTH-1:0] wake_sources
);
    
    // Filter interrupt sources based on wakeup mask
    assign wake_sources = int_src & ~wakeup_mask;
    
endmodule

// Submodule for wakeup control logic
module wakeup_controller 
#(
    parameter INT_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire sleep_mode,
    input wire [INT_WIDTH-1:0] int_src,
    input wire [INT_WIDTH-1:0] wake_sources,
    output reg wakeup,
    output reg [INT_WIDTH-1:0] pending_int
);
    
    // Pipelined signals to break critical paths
    reg [INT_WIDTH-1:0] int_src_pipe;
    reg [INT_WIDTH-1:0] wake_sources_pipe;
    reg sleep_mode_pipe;
    reg [INT_WIDTH-1:0] pending_int_pipe;
    reg wake_detect;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_pipe <= {INT_WIDTH{1'b0}};
            wake_sources_pipe <= {INT_WIDTH{1'b0}};
            sleep_mode_pipe <= 1'b0;
        end else begin
            int_src_pipe <= int_src;
            wake_sources_pipe <= wake_sources;
            sleep_mode_pipe <= sleep_mode;
        end
    end
    
    // Pipeline stage 2: Calculate wake detection and pending interrupts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wake_detect <= 1'b0;
            pending_int_pipe <= {INT_WIDTH{1'b0}};
        end else begin
            // Detect if any wake sources are active
            wake_detect <= sleep_mode_pipe && |wake_sources_pipe;
            
            // Accumulate interrupts in pending register
            pending_int_pipe <= pending_int | int_src_pipe;
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup <= 1'b0;
            pending_int <= {INT_WIDTH{1'b0}};
        end else begin
            wakeup <= wake_detect;
            pending_int <= pending_int_pipe;
        end
    end
    
endmodule