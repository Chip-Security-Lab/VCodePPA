//SystemVerilog
// Bank memory module
module bank_memory #(
    parameter DATA_WIDTH = 32,
    parameter BANK_SIZE = 16
)(
    input  wire                          clock,
    input  wire                          resetn,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]         write_data,
    input  wire                          write_enable,
    input  wire [$clog2(BANK_SIZE)-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]         read_data
);
    reg [DATA_WIDTH-1:0] memory [0:BANK_SIZE-1];
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (int i = 0; i < BANK_SIZE; i = i + 1) begin
                memory[i] <= {DATA_WIDTH{1'b0}};
            end
            read_data <= {DATA_WIDTH{1'b0}};
        end else begin
            read_data <= memory[read_addr];
            if (write_enable) begin
                memory[write_addr] <= write_data;
            end
        end
    end
endmodule

// Pipeline stage 1 module
module pipeline_stage1 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS = 4,
    parameter BANK_SIZE = 16
)(
    input  wire                          clock,
    input  wire                          resetn,
    input  wire [$clog2(NUM_BANKS)-1:0]  bank_sel_in,
    input  wire [$clog2(BANK_SIZE)-1:0]  read_addr_in,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr_in,
    input  wire [DATA_WIDTH-1:0]         write_data_in,
    input  wire                          write_enable_in,
    output reg  [$clog2(NUM_BANKS)-1:0]  bank_sel_out,
    output reg  [$clog2(BANK_SIZE)-1:0]  read_addr_out,
    output reg  [$clog2(BANK_SIZE)-1:0]  write_addr_out,
    output reg  [DATA_WIDTH-1:0]         write_data_out,
    output reg                           write_enable_out
);
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            bank_sel_out <= {($clog2(NUM_BANKS)){1'b0}};
            read_addr_out <= {($clog2(BANK_SIZE)){1'b0}};
            write_addr_out <= {($clog2(BANK_SIZE)){1'b0}};
            write_data_out <= {DATA_WIDTH{1'b0}};
            write_enable_out <= 1'b0;
        end else begin
            bank_sel_out <= bank_sel_in;
            read_addr_out <= read_addr_in;
            write_addr_out <= write_addr_in;
            write_data_out <= write_data_in;
            write_enable_out <= write_enable_in;
        end
    end
endmodule

// Pipeline stage 2 module
module pipeline_stage2 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS = 4,
    parameter BANK_SIZE = 16
)(
    input  wire                          clock,
    input  wire                          resetn,
    input  wire [DATA_WIDTH-1:0]         read_data_in,
    input  wire [$clog2(NUM_BANKS)-1:0]  bank_sel_in,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr_in,
    input  wire [DATA_WIDTH-1:0]         write_data_in,
    input  wire                          write_enable_in,
    output reg  [DATA_WIDTH-1:0]         read_data_out,
    output reg  [$clog2(NUM_BANKS)-1:0]  bank_sel_out,
    output reg  [$clog2(BANK_SIZE)-1:0]  write_addr_out,
    output reg  [DATA_WIDTH-1:0]         write_data_out,
    output reg                           write_enable_out
);
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            read_data_out <= {DATA_WIDTH{1'b0}};
            bank_sel_out <= {($clog2(NUM_BANKS)){1'b0}};
            write_addr_out <= {($clog2(BANK_SIZE)){1'b0}};
            write_data_out <= {DATA_WIDTH{1'b0}};
            write_enable_out <= 1'b0;
        end else begin
            read_data_out <= read_data_in;
            bank_sel_out <= bank_sel_in;
            write_addr_out <= write_addr_in;
            write_data_out <= write_data_in;
            write_enable_out <= write_enable_in;
        end
    end
endmodule

// Top module
module banked_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS = 4,
    parameter BANK_SIZE = 16,
    parameter TOTAL_SIZE = NUM_BANKS * BANK_SIZE
)(
    input  wire                          clock,
    input  wire                          resetn,
    input  wire [$clog2(NUM_BANKS)-1:0]  bank_sel,
    input  wire                          write_enable,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]         write_data,
    input  wire [$clog2(BANK_SIZE)-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]         read_data
);

    // Stage 1 signals
    wire [$clog2(NUM_BANKS)-1:0] bank_sel_stage1;
    wire [$clog2(BANK_SIZE)-1:0] read_addr_stage1;
    wire [$clog2(BANK_SIZE)-1:0] write_addr_stage1;
    wire [DATA_WIDTH-1:0] write_data_stage1;
    wire write_enable_stage1;

    // Stage 2 signals
    wire [DATA_WIDTH-1:0] read_data_stage2;
    wire [$clog2(NUM_BANKS)-1:0] bank_sel_stage2;
    wire [$clog2(BANK_SIZE)-1:0] write_addr_stage2;
    wire [DATA_WIDTH-1:0] write_data_stage2;
    wire write_enable_stage2;

    // Bank memory signals
    wire [DATA_WIDTH-1:0] bank_read_data [0:NUM_BANKS-1];
    wire [DATA_WIDTH-1:0] bank_write_data [0:NUM_BANKS-1];
    wire [$clog2(BANK_SIZE)-1:0] bank_write_addr [0:NUM_BANKS-1];
    wire bank_write_enable [0:NUM_BANKS-1];

    // Instantiate pipeline stage 1
    pipeline_stage1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_SIZE(BANK_SIZE)
    ) stage1 (
        .clock(clock),
        .resetn(resetn),
        .bank_sel_in(bank_sel),
        .read_addr_in(read_addr),
        .write_addr_in(write_addr),
        .write_data_in(write_data),
        .write_enable_in(write_enable),
        .bank_sel_out(bank_sel_stage1),
        .read_addr_out(read_addr_stage1),
        .write_addr_out(write_addr_stage1),
        .write_data_out(write_data_stage1),
        .write_enable_out(write_enable_stage1)
    );

    // Instantiate pipeline stage 2
    pipeline_stage2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_SIZE(BANK_SIZE)
    ) stage2 (
        .clock(clock),
        .resetn(resetn),
        .read_data_in(bank_read_data[bank_sel_stage1]),
        .bank_sel_in(bank_sel_stage1),
        .write_addr_in(write_addr_stage1),
        .write_data_in(write_data_stage1),
        .write_enable_in(write_enable_stage1),
        .read_data_out(read_data_stage2),
        .bank_sel_out(bank_sel_stage2),
        .write_addr_out(write_addr_stage2),
        .write_data_out(write_data_stage2),
        .write_enable_out(write_enable_stage2)
    );

    // Generate bank memories
    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i = i + 1) begin : bank_gen
            assign bank_write_data[i] = (bank_sel_stage2 == i) ? write_data_stage2 : {DATA_WIDTH{1'b0}};
            assign bank_write_addr[i] = (bank_sel_stage2 == i) ? write_addr_stage2 : {($clog2(BANK_SIZE)){1'b0}};
            assign bank_write_enable[i] = (bank_sel_stage2 == i) ? write_enable_stage2 : 1'b0;

            bank_memory #(
                .DATA_WIDTH(DATA_WIDTH),
                .BANK_SIZE(BANK_SIZE)
            ) bank_inst (
                .clock(clock),
                .resetn(resetn),
                .write_addr(bank_write_addr[i]),
                .write_data(bank_write_data[i]),
                .write_enable(bank_write_enable[i]),
                .read_addr(read_addr_stage1),
                .read_data(bank_read_data[i])
            );
        end
    endgenerate

    // Output stage
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end else begin
            read_data <= read_data_stage2;
        end
    end
endmodule